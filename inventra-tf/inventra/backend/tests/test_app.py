"""Tests unitaires et d'intégration pour l'API Inventra."""
import importlib
import pytest


@pytest.fixture()
def client():
    import app as app_module
    import models as models_module
    importlib.reload(models_module)
    importlib.reload(app_module)
    app_module.app.config["TESTING"] = True
    app_module.app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///:memory:"
    with app_module.app.app_context():
        models_module.db.create_all()
        yield app_module.app.test_client()
        models_module.db.session.remove()
        models_module.db.drop_all()


# ── Health ────────────────────────────────────────────────────────────
def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json()["status"] == "ok"


# ── CRUD Produits ─────────────────────────────────────────────────────
def test_list_products_empty(client):
    r = client.get("/api/products")
    assert r.status_code == 200
    assert r.get_json() == []


def test_create_product(client):
    r = client.post("/api/products", json={
        "name": "Vis M6", "category": "Visserie",
        "quantity": 500, "price": 0.05,
        "alert_threshold": 50, "unit": "pièce", "sku": "VIS-M6-001"
    })
    assert r.status_code == 201
    body = r.get_json()
    assert body["name"] == "Vis M6"
    assert body["quantity"] == 500
    assert body["low_stock"] is False


def test_create_product_missing_name(client):
    r = client.post("/api/products", json={"quantity": 10})
    assert r.status_code == 400


def test_get_product(client):
    created = client.post("/api/products",
                          json={"name": "Boulon M8", "quantity": 100}).get_json()
    r = client.get(f"/api/products/{created['id']}")
    assert r.status_code == 200
    assert r.get_json()["name"] == "Boulon M8"


def test_update_product(client):
    created = client.post("/api/products",
                          json={"name": "Écrou M6", "quantity": 200,
                                "alert_threshold": 20}).get_json()
    r = client.put(f"/api/products/{created['id']}",
                   json={"quantity": 15, "description": "Mis à jour"})
    assert r.status_code == 200
    body = r.get_json()
    assert body["quantity"] == 15
    assert body["low_stock"] is True   # 15 <= 20


def test_delete_product(client):
    created = client.post("/api/products",
                          json={"name": "Rondelle", "quantity": 50}).get_json()
    r = client.delete(f"/api/products/{created['id']}")
    assert r.status_code == 204
    r2 = client.get(f"/api/products/{created['id']}")
    assert r2.status_code == 404


def test_filter_by_category(client):
    client.post("/api/products", json={"name": "Vis", "category": "Visserie", "quantity": 10})
    client.post("/api/products", json={"name": "Câble", "category": "Électricité", "quantity": 5})
    r = client.get("/api/products?category=Visserie")
    assert r.status_code == 200
    data = r.get_json()
    assert len(data) == 1
    assert data[0]["category"] == "Visserie"


# ── Mouvements de stock ───────────────────────────────────────────────
def test_stock_in(client):
    p = client.post("/api/products",
                    json={"name": "Clé USB", "quantity": 10}).get_json()
    r = client.post(f"/api/products/{p['id']}/move",
                    json={"type": "in", "quantity": 5})
    assert r.status_code == 200
    assert r.get_json()["quantity"] == 15


def test_stock_out(client):
    p = client.post("/api/products",
                    json={"name": "Souris", "quantity": 10}).get_json()
    r = client.post(f"/api/products/{p['id']}/move",
                    json={"type": "out", "quantity": 3})
    assert r.status_code == 200
    assert r.get_json()["quantity"] == 7


def test_stock_out_insufficient(client):
    p = client.post("/api/products",
                    json={"name": "SSD", "quantity": 2}).get_json()
    r = client.post(f"/api/products/{p['id']}/move",
                    json={"type": "out", "quantity": 5})
    assert r.status_code == 409


def test_stock_invalid_type(client):
    p = client.post("/api/products",
                    json={"name": "RAM", "quantity": 10}).get_json()
    r = client.post(f"/api/products/{p['id']}/move",
                    json={"type": "transfer", "quantity": 2})
    assert r.status_code == 400


# ── Alertes ───────────────────────────────────────────────────────────
def test_alert_created_on_low_stock(client):
    client.post("/api/products", json={
        "name": "Papier A4", "quantity": 5, "alert_threshold": 10
    })
    r = client.get("/api/alerts")
    alerts = r.get_json()
    assert len(alerts) == 1
    assert alerts[0]["severity"] == "warning"


def test_alert_critical_on_zero(client):
    client.post("/api/products", json={
        "name": "Encre noire", "quantity": 0, "alert_threshold": 5
    })
    alerts = client.get("/api/alerts").get_json()
    assert any(a["severity"] == "critical" for a in alerts)


def test_alert_resolved(client):
    p = client.post("/api/products", json={
        "name": "Câble HDMI", "quantity": 3, "alert_threshold": 10
    }).get_json()
    alerts_before = client.get("/api/alerts").get_json()
    assert len(alerts_before) == 1
    alert_id = alerts_before[0]["id"]
    # Remonter le stock au dessus du seuil
    client.put(f"/api/products/{p['id']}", json={"quantity": 50})
    # Résoudre l'alerte manuellement
    r = client.put(f"/api/alerts/{alert_id}/resolve")
    assert r.status_code == 200
    assert r.get_json()["resolved"] is True


# ── Stats ─────────────────────────────────────────────────────────────
def test_stats(client):
    client.post("/api/products", json={"name": "A", "quantity": 100, "price": 9.99})
    client.post("/api/products", json={"name": "B", "quantity": 2,
                                        "alert_threshold": 5, "price": 4.50})
    r = client.get("/api/stats")
    assert r.status_code == 200
    body = r.get_json()
    assert body["total_products"] == 2
    assert body["low_stock"] == 1
    assert body["total_value"] == round(100*9.99 + 2*4.50, 2)

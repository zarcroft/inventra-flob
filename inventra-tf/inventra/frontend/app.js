/**
 * Inventra — Frontend SPA
 * Communique avec l'API Flask via fetch().
 * L'URL de base est configurable via window.INVENTRA_API_URL
 * (injectée par Nginx ou par la variable d'environnement à la build).
 */
const API = window.INVENTRA_API_URL || "http://localhost:5000";

// ── État applicatif ───────────────────────────────────────────────────
let allProducts   = [];
let editingId     = null;
let moveProductId = null;

// ── Initialisation ────────────────────────────────────────────────────
document.addEventListener("DOMContentLoaded", () => {
  setupNav();
  setupProductForm();
  setupMoveModal();
  setupFilters();
  loadAll();
  setInterval(loadAll, 30_000);   // refresh toutes les 30 secondes
});

function setupNav() {
  document.querySelectorAll(".nav-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".nav-btn, .view").forEach((el) =>
        el.classList.remove("active")
      );
      btn.classList.add("active");
      document.getElementById(`view-${btn.dataset.view}`).classList.add("active");
    });
  });
}

// ── Chargement global ─────────────────────────────────────────────────
async function loadAll() {
  await Promise.all([loadStats(), loadProducts(), loadAlerts()]);
}

// ── Stats ─────────────────────────────────────────────────────────────
async function loadStats() {
  try {
    const data = await apiFetch("/api/stats");
    document.querySelector("#stat-total  .stat-value").textContent = data.total_products;
    document.querySelector("#stat-low    .stat-value").textContent = data.low_stock;
    document.querySelector("#stat-out   .stat-value").textContent = data.out_of_stock;
    document.querySelector("#stat-value .stat-value").textContent =
      new Intl.NumberFormat("fr-FR", { minimumFractionDigits: 2 }).format(data.total_value);
  } catch { /* silencieux */ }
}

// ── Produits ──────────────────────────────────────────────────────────
async function loadProducts() {
  try {
    allProducts = await apiFetch("/api/products");
    populateCategoryFilter();
    renderProducts();
    renderDashboardTable();
  } catch { /* silencieux */ }
}

function populateCategoryFilter() {
  const sel = document.getElementById("filter-category");
  const current = sel.value;
  const cats = [...new Set(allProducts.map((p) => p.category))].sort();
  sel.innerHTML = '<option value="">Toutes les catégories</option>' +
    cats.map((c) => `<option value="${c}"${c===current?" selected":""}>${c}</option>`).join("");
}

function renderProducts() {
  const search   = document.getElementById("filter-search").value.toLowerCase();
  const category = document.getElementById("filter-category").value;
  const lowStock = document.getElementById("filter-low-stock").checked;

  let filtered = allProducts.filter((p) => {
    const matchSearch = !search || p.name.toLowerCase().includes(search) ||
                        p.sku.toLowerCase().includes(search) ||
                        p.category.toLowerCase().includes(search);
    const matchCat    = !category || p.category === category;
    const matchLow    = !lowStock  || p.low_stock;
    return matchSearch && matchCat && matchLow;
  });

  const tbody = document.getElementById("products-tbody");
  if (!filtered.length) {
    tbody.innerHTML = '<tr class="empty-row"><td colspan="9">Aucun produit trouvé</td></tr>';
    return;
  }
  tbody.innerHTML = filtered.map((p) => `
    <tr>
      <td><code>${p.sku || "—"}</code></td>
      <td><strong>${esc(p.name)}</strong>${p.description ? `<br><small style="color:var(--grey)">${esc(p.description)}</small>` : ""}</td>
      <td>${esc(p.category)}</td>
      <td><strong>${p.quantity}</strong></td>
      <td>${esc(p.unit)}</td>
      <td>${fmtPrice(p.price)}</td>
      <td>${p.alert_threshold}</td>
      <td>${stockBadge(p)}</td>
      <td>
        <button class="btn btn-sm" onclick="openMoveModal(${p.id})">📥 Stock</button>
        <button class="btn btn-sm" onclick="openEdit(${p.id})" style="margin-left:4px">✏️</button>
        <button class="btn btn-sm btn-danger" onclick="deleteProduct(${p.id})" style="margin-left:4px">🗑</button>
      </td>
    </tr>`).join("");
}

function renderDashboardTable() {
  const alerts = allProducts.filter((p) => p.low_stock);
  const tbody  = document.getElementById("dashboard-tbody");
  if (!alerts.length) {
    tbody.innerHTML = '<tr class="empty-row"><td colspan="5">✅ Tous les stocks sont suffisants</td></tr>';
    return;
  }
  tbody.innerHTML = alerts.map((p) => `
    <tr>
      <td><strong>${esc(p.name)}</strong></td>
      <td>${esc(p.category)}</td>
      <td>${p.quantity}</td>
      <td>${p.alert_threshold}</td>
      <td>${stockBadge(p)}</td>
    </tr>`).join("");
}

// ── Alertes ───────────────────────────────────────────────────────────
async function loadAlerts() {
  try {
    const alerts = await apiFetch("/api/alerts");
    const badge  = document.getElementById("alert-badge");
    badge.textContent = alerts.length;
    badge.hidden = alerts.length === 0;

    const list = document.getElementById("alerts-list");
    if (!alerts.length) {
      list.innerHTML = '<p class="empty-alerts">✅ Aucune alerte active</p>';
      return;
    }
    list.innerHTML = alerts.map((a) => `
      <div class="alert-card ${a.severity}">
        <span class="alert-icon">${a.severity === "critical" ? "🚨" : "⚠️"}</span>
        <div class="alert-body">
          <div class="alert-msg">${esc(a.message)}</div>
          <div class="alert-time">${fmtDate(a.created_at)}</div>
        </div>
        <button class="btn btn-sm" onclick="resolveAlert(${a.id})">Résoudre</button>
      </div>`).join("");
  } catch { /* silencieux */ }
}

async function resolveAlert(id) {
  await apiFetch(`/api/alerts/${id}/resolve`, { method: "PUT" });
  toast("Alerte résolue", "success");
  loadAlerts();
}

// ── CRUD produits ─────────────────────────────────────────────────────
function openNewProduct() {
  editingId = null;
  document.getElementById("modal-title").textContent = "Nouveau produit";
  document.getElementById("product-form").reset();
  document.getElementById("modal-overlay").hidden = false;
}

function openEdit(id) {
  const p = allProducts.find((x) => x.id === id);
  if (!p) return;
  editingId = id;
  document.getElementById("modal-title").textContent = "Modifier le produit";
  const form = document.getElementById("product-form");
  ["name","sku","category","unit","description"].forEach(
    (f) => { if (form[f]) form[f].value = p[f] ?? ""; });
  ["quantity","alert_threshold","price"].forEach(
    (f) => { if (form[f]) form[f].value = p[f] ?? 0; });
  document.getElementById("modal-overlay").hidden = false;
}

function closeModal() {
  document.getElementById("modal-overlay").hidden = true;
}

function setupProductForm() {
  document.getElementById("btn-new-product").onclick = openNewProduct;
  document.getElementById("btn-modal-close").onclick = closeModal;
  document.getElementById("btn-cancel").onclick      = closeModal;

  document.getElementById("btn-save").onclick = async () => {
    const form = document.getElementById("product-form");
    const data = Object.fromEntries(new FormData(form));
    data.quantity        = Number(data.quantity);
    data.alert_threshold = Number(data.alert_threshold);
    data.price           = Number(data.price);

    try {
      if (editingId) {
        await apiFetch(`/api/products/${editingId}`, { method: "PUT",  body: data });
        toast("Produit mis à jour", "success");
      } else {
        await apiFetch("/api/products",               { method: "POST", body: data });
        toast("Produit créé", "success");
      }
      closeModal();
      loadAll();
    } catch (e) {
      toast(e.message || "Erreur lors de la sauvegarde", "error");
    }
  };
}

async function deleteProduct(id) {
  const p = allProducts.find((x) => x.id === id);
  if (!confirm(`Supprimer "${p?.name}" ?`)) return;
  await apiFetch(`/api/products/${id}`, { method: "DELETE" });
  toast("Produit supprimé", "success");
  loadAll();
}

// ── Modal mouvement de stock ──────────────────────────────────────────
function openMoveModal(id) {
  moveProductId = id;
  const p = allProducts.find((x) => x.id === id);
  document.getElementById("move-title").textContent =
    `Mouvement — ${p?.name ?? ""}`;
  document.getElementById("move-qty").value  = 1;
  document.getElementById("move-type").value = "in";
  document.getElementById("move-overlay").hidden = false;
}

function setupMoveModal() {
  document.getElementById("btn-move-close").onclick  = () =>
    document.getElementById("move-overlay").hidden = true;
  document.getElementById("btn-move-cancel").onclick = () =>
    document.getElementById("move-overlay").hidden = true;

  document.getElementById("btn-move-confirm").onclick = async () => {
    const type     = document.getElementById("move-type").value;
    const quantity = Number(document.getElementById("move-qty").value);
    try {
      await apiFetch(`/api/products/${moveProductId}/move`,
        { method: "POST", body: { type, quantity } });
      document.getElementById("move-overlay").hidden = true;
      toast(`Mouvement enregistré (${type === "in" ? "+" : "-"}${quantity})`, "success");
      loadAll();
    } catch (e) {
      toast(e.message || "Erreur lors du mouvement", "error");
    }
  };
}

// ── Filtres ───────────────────────────────────────────────────────────
function setupFilters() {
  ["filter-search", "filter-category", "filter-low-stock"].forEach((id) =>
    document.getElementById(id).addEventListener("input", renderProducts));
}

// ── Utilitaires ───────────────────────────────────────────────────────
async function apiFetch(path, opts = {}) {
  const options = {
    method:  opts.method  ?? "GET",
    headers: { "Content-Type": "application/json" },
  };
  if (opts.body) options.body = JSON.stringify(opts.body);

  const r = await fetch(`${API}${path}`, options);
  if (r.status === 204) return null;
  const json = await r.json();
  if (!r.ok) throw new Error(json.error || `HTTP ${r.status}`);
  return json;
}

function stockBadge(p) {
  if (p.out_of_stock) return '<span class="tag tag-danger">🚨 Rupture</span>';
  if (p.low_stock)    return '<span class="tag tag-warning">⚠️ Stock bas</span>';
  return '<span class="tag tag-ok">✅ OK</span>';
}

function fmtPrice(v)  { return new Intl.NumberFormat("fr-FR",{style:"currency",currency:"EUR"}).format(v); }
function fmtDate(iso) { return new Date(iso).toLocaleString("fr-FR"); }
function esc(s)       { const d=document.createElement("div"); d.textContent=s??""; return d.innerHTML; }

let toastTimer;
function toast(msg, type = "info") {
  const el = document.getElementById("toast");
  el.textContent = msg;
  el.className = `toast ${type}`;
  el.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { el.hidden = true; }, 3500);
}

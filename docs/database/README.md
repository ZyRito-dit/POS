# NexSell POS — Spesifikasi Arsitektur Database & Panduan Backend

Dokumen ini mendefinisikan skema basis data relasional untuk sistem **NexSell Point of Sale (POS) UMKM**. Skema dirancang dengan standar keandalan tinggi (ISO/IEC 25010:2023, NIST SP 800-218, dan PCI-DSS) untuk menjamin integritas finansial, pelacakan inventaris nir-cacat, dan konkurensi multi-kasir.

---

## 1. File Spesifikasi CSV

Semua tabel, kolom, constraint, dan relasi telah diekspor ke dalam file CSV standar yang dapat langsung diimpor ke tools perancangan database (DBeaver, DataGrip, DbVisualizer, pgAdmin, atau spreadsheet tim backend):

1. **[`pos_schema_tables_columns.csv`](file:///d:/NexSell%20to%20POS%20Apps/pos_apps_umkm/docs/database/pos_schema_tables_columns.csv)**
   - Berisi 14 tabel lengkap dengan 120+ kolom teknis.
   - Kolom CSV: `table_name`, `column_name`, `data_type`, `is_nullable`, `default_value`, `is_pk`, `is_fk`, `is_unique`, `is_indexed`, `check_constraint`, `description`.
2. **[`pos_schema_relationships.csv`](file:///d:/NexSell%20to%20POS%20Apps/pos_apps_umkm/docs/database/pos_schema_relationships.csv)**
   - Berisi 27 relasi *Foreign Key*, kardinalitas (*Many-to-One*), aksi referensial `ON DELETE` / `ON UPDATE`, serta deskripsi bisnisnya.

---

## 2. Invarian Rekayasa Data & Keamanan Finansial (Safety Rules)

Tim backend diwajibkan menerapkan kaidah arsitektur berikut saat mengimplementasikan migrasi dan ORM:

### 2.1. Presisi Moneter (Aturan IEEE 754)
- **Larangan Keras**: Dilarang menggunakan tipe data pecahan biner (`FLOAT` atau `DOUBLE`) untuk menyimpan uang (`subtotal`, `total_amount`, `opening_cash`, `base_price`, dll.).
- **Solusi**: Seluruh nilai moneter disimpan dalam satuan integer Rupiah utuh menggunakan tipe data `BIGINT`. Hal ini menghilangkan galat pembulatan desimal (*roundoff anomaly*).

### 2.2. Pencegahan Balapan Stok (Concurrency Control)
- Kolom `products.version` (`BIGINT`) disediakan untuk *Optimistic Concurrency Control (OCC)*.
- Saat kasir melakukan checkout, mutasi stok diverifikasi dengan kueri ber-versioning:
  ```sql
  UPDATE products 
  SET stock = stock - :qty, version = version + 1 
  WHERE id = :id AND version = :expected_version AND stock >= :qty;
  ```
- Jika baris terdampak bernilai `0`, rollback transaksi dan kembalikan galat ke kasir bahwa stok telah berubah atau habis.

### 2.3. Audit Imutabel Buku Besar (Append-Only Ledgers)
- Tabel `inventory_movements` dan `audit_logs` bersifat **append-only** (hanya `INSERT`, dilarang `UPDATE` dan `DELETE`).
- Nilai stok fisik produk dihitung atau diverifikasi silang terhadap total pergerakan stok historis.

### 2.4. Idempotensi Transaksi Kasir (Anti-Double Charge)
- Kolom `sales.idempotency_key` (`VARCHAR(64) UNIQUE`) mencegah duplikasi pembuatan nota saat koneksi internet kasir (HP/Tablet) terputus lalu kasir menekan tombol "Bayar" berulang kali.

### 2.5. Snapshot Harga & Nama Produk
- Tabel `sale_items` menyimpan `sku_snapshot`, `product_name_snapshot`, dan `cost_price_snapshot` (HPP).
- Jika admin di masa depan mengubah nama produk atau menaikkan harga jual, riwayat nota transaksi masa lalu tetap akurat secara hukum dan akuntansi.

### 2.6. Perlindungan Penghapusan Data (Referential Integrity)
- Seluruh relasi penjualan (`sales`, `sale_items`, `payments`, `cashier_shifts`) menggunakan aturan `ON DELETE RESTRICT`. Data transaksi finansial tidak boleh terhapus secara sengaja maupun tidak sengaja melalui penghapusan induk.

---

## 3. DDL PostgreSQL Referensi (Migration Blueprint)

```sql
-- 1. Tenant & Stores
CREATE TABLE tenants (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(32) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    legal_name VARCHAR(255),
    tax_id VARCHAR(64),
    phone VARCHAR(32) NOT NULL,
    email VARCHAR(128) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

CREATE TABLE stores (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    code VARCHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(64) NOT NULL,
    postal_code VARCHAR(16),
    phone VARCHAR(32),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_stores_tenant_code UNIQUE (tenant_id, code)
);

-- 2. Users & Shifts
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    username VARCHAR(64) NOT NULL,
    email VARCHAR(128) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(128) NOT NULL,
    phone VARCHAR(32),
    role VARCHAR(32) NOT NULL CHECK (role IN ('owner','tenant-admin','operator','staff','technician')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_users_tenant_username UNIQUE (tenant_id, username)
);

CREATE TABLE pos_terminals (
    id BIGSERIAL PRIMARY KEY,
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    machine_code VARCHAR(32) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    device_fingerprint VARCHAR(255),
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active','inactive','maintenance')),
    payment_gateway_provider VARCHAR(64) NOT NULL DEFAULT 'midtrans_qris',
    printer_interface VARCHAR(64) NOT NULL DEFAULT 'thermal_58mm',
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ
);

CREATE TABLE cashier_shifts (
    id BIGSERIAL PRIMARY KEY,
    terminal_id BIGINT NOT NULL REFERENCES pos_terminals(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    cashier_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    shift_number INTEGER NOT NULL DEFAULT 1 CHECK (shift_number >= 1),
    opened_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMPTZ,
    opening_cash BIGINT NOT NULL CHECK (opening_cash >= 0),
    expected_closing_cash BIGINT CHECK (expected_closing_cash >= 0),
    actual_closing_cash BIGINT CHECK (actual_closing_cash >= 0),
    cash_discrepancy BIGINT DEFAULT 0,
    status VARCHAR(32) NOT NULL DEFAULT 'open' CHECK (status IN ('open','closed','reconciled')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. Catalog & Inventory
CREATE TABLE product_categories (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    name VARCHAR(64) NOT NULL,
    slug VARCHAR(64) NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_categories_tenant_slug UNIQUE (tenant_id, slug)
);

CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    category_id BIGINT NOT NULL REFERENCES product_categories(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    sku VARCHAR(64) NOT NULL,
    barcode VARCHAR(64),
    name VARCHAR(128) NOT NULL,
    description TEXT,
    packaging_info VARCHAR(255),
    cost_price BIGINT NOT NULL DEFAULT 0 CHECK (cost_price >= 0),
    base_price BIGINT NOT NULL CHECK (base_price >= 0),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    min_stock_alert INTEGER NOT NULL DEFAULT 5 CHECK (min_stock_alert >= 0),
    image_url VARCHAR(512),
    is_active BOOLEAN NOT NULL DEFAULT true,
    version BIGINT NOT NULL DEFAULT 1 CHECK (version >= 1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_products_tenant_sku UNIQUE (tenant_id, sku)
);

CREATE TABLE inventory_movements (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    movement_type VARCHAR(32) NOT NULL CHECK (movement_type IN ('sale','restock','adjustment','return','waste','transfer_in','transfer_out')),
    quantity_change INTEGER NOT NULL CHECK (quantity_change <> 0),
    previous_stock INTEGER NOT NULL CHECK (previous_stock >= 0),
    resulting_stock INTEGER NOT NULL CHECK (resulting_stock >= 0),
    reference_type VARCHAR(32) NOT NULL CHECK (reference_type IN ('sale_invoice','manual_adjustment','purchase_order','waste_log')),
    reference_id VARCHAR(64),
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Sales & Payments
CREATE TABLE sales (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    store_id BIGINT NOT NULL REFERENCES stores(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    terminal_id BIGINT NOT NULL REFERENCES pos_terminals(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    shift_id BIGINT NOT NULL REFERENCES cashier_shifts(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    cashier_user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    invoice_number VARCHAR(64) NOT NULL UNIQUE,
    idempotency_key VARCHAR(64) NOT NULL UNIQUE,
    customer_name VARCHAR(128) DEFAULT 'Pelanggan Umum',
    subtotal BIGINT NOT NULL CHECK (subtotal >= 0),
    discount_amount BIGINT NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    tax_amount BIGINT NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    total_amount BIGINT NOT NULL CHECK (total_amount >= 0),
    payment_status VARCHAR(32) NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid','partially_paid','paid','refunded')),
    status VARCHAR(32) NOT NULL DEFAULT 'completed' CHECK (status IN ('pending','completed','cancelled','refunded')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sale_items (
    id BIGSERIAL PRIMARY KEY,
    sale_id BIGINT NOT NULL REFERENCES sales(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    product_id BIGINT NOT NULL REFERENCES products(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    sku_snapshot VARCHAR(64) NOT NULL,
    product_name_snapshot VARCHAR(128) NOT NULL,
    cost_price_snapshot BIGINT NOT NULL DEFAULT 0 CHECK (cost_price_snapshot >= 0),
    unit_price BIGINT NOT NULL CHECK (unit_price >= 0),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    subtotal BIGINT NOT NULL CHECK (subtotal >= 0),
    discount_amount BIGINT NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    notes VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    sale_id BIGINT NOT NULL REFERENCES sales(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    payment_method VARCHAR(32) NOT NULL CHECK (payment_method IN ('cash','qris','debit','credit','transfer')),
    gateway_provider VARCHAR(64) NOT NULL DEFAULT 'cash' CHECK (gateway_provider IN ('cash','midtrans','xendit','edc_bca','edc_mandiri')),
    amount BIGINT NOT NULL CHECK (amount > 0),
    amount_paid BIGINT NOT NULL CHECK (amount_paid >= 0),
    change_amount BIGINT NOT NULL DEFAULT 0 CHECK (change_amount >= 0),
    gateway_reference VARCHAR(128),
    status VARCHAR(32) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','settled','failed','expired','refunded')),
    settled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5. Notifications & Audit Logs
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE,
    store_id BIGINT REFERENCES stores(id) ON DELETE CASCADE ON UPDATE CASCADE,
    target_user_id BIGINT REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    title VARCHAR(128) NOT NULL,
    message TEXT NOT NULL,
    category VARCHAR(32) NOT NULL CHECK (category IN ('stock_alert','qris_pending','shift_alert','sync_success','security_alert')),
    severity VARCHAR(16) NOT NULL DEFAULT 'info' CHECK (severity IN ('info','warning','error','success')),
    reference_type VARCHAR(32),
    reference_id VARCHAR(64),
    is_read BOOLEAN NOT NULL DEFAULT false,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    action VARCHAR(64) NOT NULL,
    entity_name VARCHAR(64) NOT NULL,
    entity_id VARCHAR(64) NOT NULL,
    before_payload JSONB,
    after_payload JSONB,
    ip_address VARCHAR(45) NOT NULL,
    user_agent VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 6. Essential Performance Indexes
CREATE INDEX idx_products_tenant_cat ON products(tenant_id, category_id, is_active);
CREATE INDEX idx_products_tenant_sku ON products(tenant_id, sku);
CREATE INDEX idx_sales_tenant_created ON sales(tenant_id, created_at DESC);
CREATE INDEX idx_sales_invoice ON sales(invoice_number);
CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_payments_sale ON payments(sale_id);
CREATE INDEX idx_movements_prod ON inventory_movements(product_id, created_at DESC);
CREATE INDEX idx_notifications_user ON notifications(target_user_id, is_read, created_at DESC);
CREATE INDEX idx_audit_logs_tenant_time ON audit_logs(tenant_id, created_at DESC);
```

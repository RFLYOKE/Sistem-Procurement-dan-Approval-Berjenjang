-- ============================================================
-- DATABASE: Sistem Procurement dan Approval Berjenjang
-- Jalankan file ini untuk setup lengkap dari awal
-- CATATAN: Untuk Aiven, script ini dijalankan langsung di 'defaultdb'
--          Tidak perlu CREATE DATABASE / USE karena Aiven hanya izinkan 1 DB
-- ============================================================

-- ============================================================
-- BAGIAN 1: CREATE TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    email      VARCHAR(100) NOT NULL UNIQUE,
    password   VARCHAR(255) NOT NULL,
    role       ENUM('admin','requester','supervisor','finance','purchasing') NOT NULL DEFAULT 'requester',
    department VARCHAR(100),
    is_active  BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS items (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    code            VARCHAR(50)  NOT NULL UNIQUE,
    name            VARCHAR(200) NOT NULL,
    description     TEXT,
    category        ENUM('barang','jasa') NOT NULL,
    unit            VARCHAR(50)  NOT NULL,
    image           VARCHAR(255),
    estimated_price DECIMAL(15,2) DEFAULT 0,
    is_active       BOOLEAN DEFAULT TRUE,
    created_by      INT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS vendors (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    code              VARCHAR(50)  NOT NULL UNIQUE,
    name              VARCHAR(200) NOT NULL,
    contact_person    VARCHAR(100),
    phone             VARCHAR(20)  NOT NULL,
    email             VARCHAR(100),
    address           TEXT,
    npwp              VARCHAR(30),
    bank_name         VARCHAR(100),
    bank_account      VARCHAR(50),
    bank_account_name VARCHAR(100),
    category          VARCHAR(100),
    is_active         BOOLEAN DEFAULT TRUE,
    created_by        INT,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS procurement_requests (
    id                    INT AUTO_INCREMENT PRIMARY KEY,
    request_number        VARCHAR(50) NOT NULL UNIQUE,
    title                 VARCHAR(200) NOT NULL,
    description           TEXT,
    requester_id          INT NOT NULL,
    department            VARCHAR(100),
    required_date         DATE,
    total_estimated_price DECIMAL(15,2) DEFAULT 0,
    status ENUM('draft','submitted','approved_supervisor','approved_finance',
                'approved_purchasing','rejected','purchased','received') NOT NULL DEFAULT 'draft',
    priority ENUM('low','medium','high') DEFAULT 'medium',
    notes    TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (requester_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS procurement_request_items (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    request_id      INT NOT NULL,
    item_id         INT NOT NULL,
    quantity        DECIMAL(10,2) NOT NULL,
    unit            VARCHAR(50),
    estimated_price DECIMAL(15,2) NOT NULL,
    total_price     DECIMAL(15,2) GENERATED ALWAYS AS (quantity * estimated_price) STORED,
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES procurement_requests(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id)    REFERENCES items(id)
);

CREATE TABLE IF NOT EXISTS approval_histories (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    request_id    INT NOT NULL,
    approver_id   INT NOT NULL,
    role          VARCHAR(50) NOT NULL,
    action        ENUM('submitted','approved','rejected') NOT NULL,
    notes         TEXT,
    status_before VARCHAR(50),
    status_after  VARCHAR(50),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id)  REFERENCES procurement_requests(id),
    FOREIGN KEY (approver_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS purchase_orders (
    id                     INT AUTO_INCREMENT PRIMARY KEY,
    po_number              VARCHAR(50) NOT NULL UNIQUE,
    request_id             INT NOT NULL,
    vendor_id              INT NOT NULL,
    created_by             INT NOT NULL,
    po_date                DATE NOT NULL,
    expected_delivery_date DATE,
    total_amount           DECIMAL(15,2) NOT NULL DEFAULT 0,
    status ENUM('draft','sent','confirmed','completed','cancelled') DEFAULT 'draft',
    payment_terms          VARCHAR(100),
    delivery_address       TEXT,
    notes                  TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (request_id) REFERENCES procurement_requests(id),
    FOREIGN KEY (vendor_id)  REFERENCES vendors(id),
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    po_id       INT NOT NULL,
    item_id     INT NOT NULL,
    quantity    DECIMAL(10,2) NOT NULL,
    unit        VARCHAR(50),
    unit_price  DECIMAL(15,2) NOT NULL,
    total_price DECIMAL(15,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    notes       TEXT,
    FOREIGN KEY (po_id)   REFERENCES purchase_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(id)
);

CREATE TABLE IF NOT EXISTS goods_receipts (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    gr_number     VARCHAR(50) NOT NULL UNIQUE,
    po_id         INT NOT NULL,
    request_id    INT NOT NULL,
    received_by   INT NOT NULL,
    received_date DATE NOT NULL,
    status        ENUM('partial','complete') DEFAULT 'complete',
    notes         TEXT,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (po_id)       REFERENCES purchase_orders(id),
    FOREIGN KEY (request_id)  REFERENCES procurement_requests(id),
    FOREIGN KEY (received_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS goods_receipt_items (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    gr_id             INT NOT NULL,
    item_id           INT NOT NULL,
    po_item_id        INT NOT NULL,
    quantity_ordered  DECIMAL(10,2),
    quantity_received DECIMAL(10,2) NOT NULL,
    condition_notes   TEXT,
    FOREIGN KEY (gr_id)      REFERENCES goods_receipts(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id)    REFERENCES items(id),
    FOREIGN KEY (po_item_id) REFERENCES purchase_order_items(id)
);

-- ============================================================
-- BAGIAN 2: SAMPLE DATA
-- ============================================================
-- CATATAN: Semua user menggunakan password: password123
-- Untuk generate hash baru, jalankan perintah berikut di terminal:
--   node -e "const b=require('bcryptjs');b.hash('password123',10,(e,h)=>console.log(h))"
-- ============================================================

-- Users: Admin default (password: password123)
-- Hash berikut adalah bcrypt dari password123 (cost=10)
INSERT INTO users (id, name, email, password, role, department, is_active) VALUES
(1, 'Admin Sistem',    'admin@procurement.id',      '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'admin',      'IT',       TRUE),
(2, 'Budi Requester',  'budi@procurement.id',        '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'requester',  'Umum',     TRUE),
(3, 'Siti Supervisor', 'siti@procurement.id',        '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'supervisor', 'Keuangan', TRUE),
(4, 'Rudi Finance',    'rudi@procurement.id',        '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'finance',    'Keuangan', TRUE),
(5, 'Dewi Purchasing', 'dewi@procurement.id',        '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'purchasing', 'Pengadaan',TRUE);

-- Items: 3 barang, 2 jasa
INSERT INTO items (code, name, description, category, unit, estimated_price, created_by) VALUES
('ITM-006', 'Meja Kerja Ergonomis',          'Standing desk adjustable',            'barang', 'unit',   2500000, 1),
('ITM-007', 'Mouse Wireless Logitech MX',    'Mouse ergonomis wireless',            'barang', 'unit',    350000, 1),
('SVC-003', 'Jasa Maintenance Jaringan',     'Pemeliharaan jaringan bulanan',       'jasa',   'bulan',  3000000, 1),
('SVC-004', 'Jasa Instalasi Software',       'Instalasi dan konfigurasi software',  'jasa',   'paket',  5000000, 1);

-- Vendors: 2 vendor
INSERT INTO vendors (code, name, contact_person, phone, email, bank_name, bank_account, bank_account_name, category, created_by) VALUES
('VND-002', 'CV Karya Solusi Mandiri',   'Ani Wulandari', '08222222222', 'ani@karyasolusi.id',   'Mandiri','0987654321', 'CV Karya Solusi Mandiri',   'Furniture',   1),
('VND-003', 'PT Layanan Prima Utama',    'Cici Rahayu',   '08333333333', 'cici@layanprima.id',   'BNI',    '1122334455', 'PT Layanan Prima Utama',    'Services',    1);

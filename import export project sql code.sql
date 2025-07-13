-- Database creation
CREATE DATABASE Import_Export1;
USE Import_Export1;

-- Organizations table
CREATE TABLE Organizations (
    OrgID INT PRIMARY KEY,
    OrgName VARCHAR(255) NOT NULL,
    OrgType VARCHAR(50) NOT NULL CHECK (OrgType IN ('Supplier', 'Customer', 'Logistics Provider')),
    Address VARCHAR(255),
    City VARCHAR(100),
    Country VARCHAR(100),
    ContactPerson VARCHAR(255),
    Email VARCHAR(255),
    Phone VARCHAR(50)
);

-- Goods table
CREATE TABLE Goods (
    GoodsID INT PRIMARY KEY AUTO_INCREMENT,
    Description TEXT NOT NULL,
    HSCode VARCHAR(20) NOT NULL UNIQUE,
    UnitOfMeasure VARCHAR(50) NOT NULL
);

-- Shipments table
CREATE TABLE Shipments (
    ShipmentID INT PRIMARY KEY AUTO_INCREMENT,
    ShipmentType VARCHAR(10) NOT NULL CHECK (ShipmentType IN ('Import', 'Export')),
    ReferenceNumber VARCHAR(100) NOT NULL UNIQUE,
    OrgID_Supplier INT,
    OrgID_Customer INT,
    OrgID_Logistics INT,
    DispatchDate DATE,
    EstimatedArrivalDate DATE,
    ActualArrivalDate DATE,
    CustomsClearanceDate DATE,
    CurrentStatus VARCHAR(100) NOT NULL,
    TotalCost DECIMAL(18,2),
    Currency VARCHAR(3),
    FOREIGN KEY (OrgID_Supplier) REFERENCES Organizations(OrgID),
    FOREIGN KEY (OrgID_Customer) REFERENCES Organizations(OrgID),
    FOREIGN KEY (OrgID_Logistics) REFERENCES Organizations(OrgID)
);

-- ShipmentGoods table
CREATE TABLE ShipmentGoods (
    ShipmentID INT,
    GoodsID INT,
    Quantity DECIMAL(18,3) NOT NULL,
    Value DECIMAL(18,2) NOT NULL,
    PRIMARY KEY (ShipmentID, GoodsID),
    FOREIGN KEY (ShipmentID) REFERENCES Shipments(ShipmentID),
    FOREIGN KEY (GoodsID) REFERENCES Goods(GoodsID)
);

-- ShipmentCosts table
CREATE TABLE ShipmentCosts (
    CostID INT PRIMARY KEY AUTO_INCREMENT,
    ShipmentID INT NOT NULL,
    CostType VARCHAR(100) NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    Currency VARCHAR(3) NOT NULL,
    CostDate DATE,
    FOREIGN KEY (ShipmentID) REFERENCES Shipments(ShipmentID)
);

-- Documents table
CREATE TABLE Documents (
    DocumentID INT PRIMARY KEY AUTO_INCREMENT,
    ShipmentID INT NOT NULL,
    DocumentType VARCHAR(100) NOT NULL,
    DocumentNumber VARCHAR(100),
    IssueDate DATE,
    FilePath VARCHAR(255),
    Description TEXT,
    FOREIGN KEY (ShipmentID) REFERENCES Shipments(ShipmentID)
);

-- Inventory table
CREATE TABLE Inventory (
    InventoryID INT PRIMARY KEY AUTO_INCREMENT,
    GoodsID INT NOT NULL,
    Date DATETIME NOT NULL,
    ChangeType VARCHAR(10) NOT NULL CHECK (ChangeType IN ('Import', 'Export', 'Adjustment')),
    QuantityChange DECIMAL(18,3) NOT NULL,
    CurrentStock DECIMAL(18,3) NOT NULL,
    ShipmentID INT,
    FOREIGN KEY (GoodsID) REFERENCES Goods(GoodsID),
    FOREIGN KEY (ShipmentID) REFERENCES Shipments(ShipmentID)
);

-- Insert sample data into Organizations
INSERT INTO Organizations (OrgID, OrgName, OrgType, Address, City, Country, ContactPerson, Email, Phone)
VALUES
(1, 'China National Import Co.', 'Supplier', '123 Export Street', 'Shanghai', 'China', 'Li Wei', 'liwei@cnimport.com', '+86 21 12345678'),
(2, 'USA Global Export Inc.', 'Customer', '456 Trade Avenue', 'New York', 'United States', 'John Smith', 'jsmith@usexport.com', '+1 212 5551234'),
(3, 'Euro Logistics GmbH', 'Logistics Provider', '789 Transport Road', 'Hamburg', 'Germany', 'Hans Mueller', 'h.mueller@eurolog.com', '+49 40 9876543'),
(4, 'India Textile Export', 'Supplier', '321 Fabric Lane', 'Mumbai', 'India', 'Raj Patel', 'r.patel@indiatex.com', '+91 22 24681012'),
(5, 'UK Retail Importers', 'Customer', '654 Commerce Street', 'London', 'United Kingdom', 'Emma Wilson', 'e.wilson@ukretail.co.uk', '+44 20 78901234');

-- Insert sample data into Goods
INSERT INTO Goods (Description, HSCode, UnitOfMeasure)
VALUES
('Smartphones', '851712', 'Units'),
('Cotton T-Shirts', '610910', 'Pieces'),
('LED Televisions', '852872', 'Units'),
('Coffee Beans', '090111', 'Kilograms'),
('Aluminum Sheets', '760612', 'Square Meters');

-- Insert sample data into Shipments
INSERT INTO Shipments (ShipmentType, ReferenceNumber, OrgID_Supplier, OrgID_Customer, OrgID_Logistics, 
                      DispatchDate, EstimatedArrivalDate, ActualArrivalDate, CustomsClearanceDate, 
                      CurrentStatus, TotalCost, Currency)
VALUES
('Import', 'IMP-2023-001', 1, NULL, 3, '2023-01-10', '2023-02-15', '2023-02-14', '2023-02-16', 'Delivered', 25000.00, 'USD'),
('Export', 'EXP-2023-001', NULL, 2, 3, '2023-02-05', '2023-03-10', '2023-03-08', '2023-03-09', 'Delivered', 18000.00, 'USD'),
('Import', 'IMP-2023-002', 4, NULL, 3, '2023-03-15', '2023-04-20', '2023-04-18', '2023-04-19', 'Delivered', 32000.00, 'USD'),
('Export', 'EXP-2023-002', NULL, 5, 3, '2023-04-01', '2023-05-06', '2023-05-05', '2023-05-07', 'In Transit', 22000.00, 'USD'),
('Import', 'IMP-2023-003', 1, NULL, 3, '2023-05-12', '2023-06-17', NULL, NULL, 'In Customs', 41000.00, 'USD');

-- Insert sample data into ShipmentGoods
INSERT INTO ShipmentGoods (ShipmentID, GoodsID, Quantity, Value)
VALUES
(1, 1, 500, 20000.00),
(1, 3, 100, 5000.00),
(2, 2, 1000, 15000.00),
(2, 5, 200, 3000.00),
(3, 2, 1500, 22000.00),
(3, 4, 500, 10000.00),
(4, 1, 300, 15000.00),
(4, 3, 50, 7000.00),
(5, 1, 600, 24000.00),
(5, 3, 120, 17000.00);

-- Insert sample data into ShipmentCosts
INSERT INTO ShipmentCosts (ShipmentID, CostType, Amount, Currency, CostDate)
VALUES
(1, 'Freight', 3000.00, 'USD', '2023-01-10'),
(1, 'Insurance', 500.00, 'USD', '2023-01-10'),
(1, 'Customs Duty', 2000.00, 'USD', '2023-02-16'),
(2, 'Freight', 2500.00, 'USD', '2023-02-05'),
(2, 'Insurance', 300.00, 'USD', '2023-02-05'),
(3, 'Freight', 3500.00, 'USD', '2023-03-15'),
(3, 'Insurance', 700.00, 'USD', '2023-03-15'),
(3, 'Customs Duty', 2800.00, 'USD', '2023-04-19'),
(4, 'Freight', 2800.00, 'USD', '2023-04-01'),
(4, 'Insurance', 400.00, 'USD', '2023-04-01'),
(5, 'Freight', 3800.00, 'USD', '2023-05-12'),
(5, 'Insurance', 900.00, 'USD', '2023-05-12');

-- Insert sample data into Documents
INSERT INTO Documents (ShipmentID, DocumentType, DocumentNumber, IssueDate, FilePath, Description)
VALUES
(1, 'Commercial Invoice', 'INV-2023-001', '2023-01-08', '/documents/inv001.pdf', 'Invoice for smartphones and TVs'),
(1, 'Bill of Lading', 'BL-2023-001', '2023-01-09', '/documents/bl001.pdf', 'Sea freight bill of lading'),
(2, 'Commercial Invoice', 'INV-2023-002', '2023-02-03', '/documents/inv002.pdf', 'Invoice for t-shirts and aluminum'),
(2, 'Packing List', 'PKG-2023-002', '2023-02-04', '/documents/pkg002.pdf', 'Detailed packing list'),
(3, 'Commercial Invoice', 'INV-2023-003', '2023-03-12', '/documents/inv003.pdf', 'Invoice for textiles and coffee'),
(3, 'Certificate of Origin', 'COO-2023-001', '2023-03-13', '/documents/coo001.pdf', 'India origin certificate'),
(4, 'Commercial Invoice', 'INV-2023-004', '2023-03-30', '/documents/inv004.pdf', 'Invoice for electronics'),
(5, 'Proforma Invoice', 'PRO-2023-001', '2023-05-10', '/documents/pro001.pdf', 'Preliminary invoice');

-- Insert sample data into Inventory
INSERT INTO Inventory (GoodsID, Date, ChangeType, QuantityChange, CurrentStock, ShipmentID)
VALUES
(1, '2023-02-14', 'Import', 500, 500, 1),
(3, '2023-02-14', 'Import', 100, 100, 1),
(2, '2023-03-08', 'Export', -1000, -1000, 2),
(5, '2023-03-08', 'Export', -200, -200, 2),
(2, '2023-04-18', 'Import', 1500, 500, 3),
(4, '2023-04-18', 'Import', 500, 500, 3),
(1, '2023-05-05', 'Export', -300, 200, 4),
(3, '2023-05-05', 'Export', -50, 50, 4),
(1, '2023-06-01', 'Adjustment', 50, 250, NULL),
(3, '2023-06-01', 'Adjustment', 10, 60, NULL);

-- Query 1: Update a shipment's total cost
UPDATE Shipments
SET TotalCost = 52000.00
WHERE ShipmentID = 1;

-- Query 2: Delete a shipment record
DELETE FROM ShipmentGoods WHERE ShipmentID = 5;
DELETE FROM ShipmentCosts WHERE ShipmentID = 5;
DELETE FROM Documents WHERE ShipmentID = 5;
DELETE FROM Shipments WHERE ShipmentID = 5;

-- Query 3: View all shipment records
SELECT * FROM Shipments;

-- Query 4: Country-wise trade summary
SELECT 
    o.Country AS country, 
    s.ShipmentType AS trade_type, 
    SUM(sg.Value) AS total_value
FROM Shipments s
JOIN ShipmentGoods sg ON s.ShipmentID = sg.ShipmentID
JOIN Organizations o ON 
    (s.ShipmentType = 'Import' AND s.OrgID_Supplier = o.OrgID) OR
    (s.ShipmentType = 'Export' AND s.OrgID_Customer = o.OrgID)
GROUP BY o.Country, s.ShipmentType
ORDER BY total_value DESC;

-- Query 5: All Imports from China
SELECT 
    s.*, 
    o.OrgName AS supplier_name,
    o.Country AS source_country
FROM Shipments s
JOIN Organizations o ON s.OrgID_Supplier = o.OrgID
WHERE s.ShipmentType = 'Import' AND o.Country = 'China';

-- Query 6: Top 3 Export destination countries by value
SELECT
    o.Country AS destination_country,
    SUM(sg.Value) AS export_value
FROM Shipments s
JOIN ShipmentGoods sg ON s.ShipmentID = sg.ShipmentID
JOIN Organizations o ON s.OrgID_Customer = o.OrgID
WHERE s.ShipmentType = 'Export'
GROUP BY o.Country
ORDER BY export_value DESC
LIMIT 3;

-- Query 7: Get shipments between dates
SELECT * FROM Shipments
WHERE DispatchDate BETWEEN '2023-03-01' AND '2023-05-31';

-- Query 8: Total Import vs Export value
SELECT 
    ShipmentType, 
    SUM(TotalCost) AS total_value
FROM Shipments
GROUP BY ShipmentType;

-- Query 9: Value of goods by shipment type and country
SELECT 
    s.ShipmentType,
    o.Country,
    SUM(sg.Value) AS total_goods_value,
    SUM(s.TotalCost) AS total_shipment_cost
FROM Shipments s
JOIN ShipmentGoods sg ON s.ShipmentID = sg.ShipmentID
JOIN Organizations o ON 
    (s.ShipmentType = 'Import' AND s.OrgID_Supplier = o.OrgID) OR
    (s.ShipmentType = 'Export' AND s.OrgID_Customer = o.OrgID)
GROUP BY s.ShipmentType, o.Country
ORDER BY s.ShipmentType, total_goods_value DESC;

-- Query 10: Shipment status overview
SELECT 
    CurrentStatus,
    COUNT(*) AS shipment_count,
    SUM(TotalCost) AS total_value
FROM Shipments
GROUP BY CurrentStatus
ORDER BY shipment_count DESC;

-- Query 11: Inventory changes by goods type
SELECT 
    g.Description,
    g.HSCode,
    SUM(CASE WHEN i.ChangeType = 'Import' THEN i.QuantityChange ELSE 0 END) AS total_imported,
    SUM(CASE WHEN i.ChangeType = 'Export' THEN i.QuantityChange ELSE 0 END) AS total_exported,
    MAX(i.CurrentStock) AS current_stock
FROM Inventory i
JOIN Goods g ON i.GoodsID = g.GoodsID
GROUP BY g.Description, g.HSCode
ORDER BY current_stock DESC;

-- Query 12: Document checklist for shipments
SELECT 
    s.ReferenceNumber,
    s.ShipmentType,
    GROUP_CONCAT(d.DocumentType SEPARATOR ', ') AS documents_attached,
    COUNT(d.DocumentID) AS document_count
FROM Shipments s
LEFT JOIN Documents d ON d.ShipmentID = s.ShipmentID
GROUP BY s.ReferenceNumber, s.ShipmentType
ORDER BY s.ShipmentType, document_count DESC;

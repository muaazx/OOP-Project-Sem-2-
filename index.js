const express = require('express');
const cors = require('cors');
const path = require('path');
const db = require('./database');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Serve the main HTML file
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Get all tables data
app.get('/api/tables/:tableName', async (req, res) => {
    try {
        const [rows] = await db.query(`SELECT * FROM ${req.params.tableName}`);
        res.json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get all shipments with related organization details
app.get('/api/shipments', async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT s.*, 
                   sup.OrgName as SupplierName,
                   cust.OrgName as CustomerName,
                   log.OrgName as LogisticsName
            FROM Shipments s
            LEFT JOIN Organizations sup ON s.OrgID_Supplier = sup.OrgID
            LEFT JOIN Organizations cust ON s.OrgID_Customer = cust.OrgID
            LEFT JOIN Organizations log ON s.OrgID_Logistics = log.OrgID
        `);
        res.json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get all organizations
app.get('/api/organizations', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM Organizations');
        res.json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get all goods
app.get('/api/goods', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT * FROM Goods');
        res.json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Add new organization
app.post('/api/organizations', async (req, res) => {
    try {
        const { OrgName, OrgType, Address, City, Country, ContactPerson, Email, Phone } = req.body;
        const [result] = await db.query(
            'INSERT INTO Organizations (OrgName, OrgType, Address, City, Country, ContactPerson, Email, Phone) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            [OrgName, OrgType, Address, City, Country, ContactPerson, Email, Phone]
        );
        res.status(201).json({ id: result.insertId });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Add new goods
app.post('/api/goods', async (req, res) => {
    try {
        const { Description, HSCode, UnitOfMeasure } = req.body;
        const [result] = await db.query(
            'INSERT INTO Goods (Description, HSCode, UnitOfMeasure) VALUES (?, ?, ?)',
            [Description, HSCode, UnitOfMeasure]
        );
        res.status(201).json({ id: result.insertId });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Add new shipment
app.post('/api/shipments', async (req, res) => {
    try {
        const { 
            ShipmentType, 
            ReferenceNumber, 
            OrgID_Supplier, 
            OrgID_Customer, 
            DispatchDate, 
            EstimatedArrivalDate, 
            CurrentStatus, 
            TotalCost, 
            Currency 
        } = req.body;

        const [result] = await db.query(
            `INSERT INTO Shipments (
                ShipmentType, 
                ReferenceNumber, 
                OrgID_Supplier, 
                OrgID_Customer, 
                DispatchDate, 
                EstimatedArrivalDate, 
                CurrentStatus, 
                TotalCost, 
                Currency
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                ShipmentType, 
                ReferenceNumber, 
                OrgID_Supplier || null, 
                OrgID_Customer || null, 
                DispatchDate, 
                EstimatedArrivalDate, 
                CurrentStatus, 
                TotalCost, 
                Currency
            ]
        );
        res.status(201).json({ id: result.insertId });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get trade summary
app.get('/api/trade-summary', async (req, res) => {
    try {
        // Get total import/export values
        const [tradeValues] = await db.query(`
            SELECT 
                ShipmentType,
                COUNT(*) as ShipmentCount,
                SUM(TotalCost) as TotalValue,
                MIN(DispatchDate) as EarliestDate,
                MAX(DispatchDate) as LatestDate
            FROM Shipments
            GROUP BY ShipmentType
        `);

        // Get top trading partners
        const [tradingPartners] = await db.query(`
            SELECT 
                o.Country,
                o.OrgType,
                COUNT(*) as TransactionCount,
                SUM(s.TotalCost) as TotalValue
            FROM Shipments s
            JOIN Organizations o ON 
                (s.OrgID_Supplier = o.OrgID OR s.OrgID_Customer = o.OrgID)
            WHERE o.OrgType IN ('Supplier', 'Customer')
            GROUP BY o.Country, o.OrgType
            ORDER BY TotalValue DESC
            LIMIT 10
        `);

        // Get most traded goods
        const [tradedGoods] = await db.query(`
            SELECT 
                g.Description,
                g.HSCode,
                SUM(sg.Quantity) as TotalQuantity,
                SUM(sg.Value) as TotalValue
            FROM ShipmentGoods sg
            JOIN Goods g ON sg.GoodsID = g.GoodsID
            GROUP BY g.GoodsID
            ORDER BY TotalValue DESC
            LIMIT 10
        `);

        res.json({
            tradeValues,
            tradingPartners,
            tradedGoods
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get inventory summary
app.get('/api/inventory-summary', async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT 
                g.Description,
                g.HSCode,
                g.UnitOfMeasure,
                SUM(CASE WHEN i.ChangeType = 'Import' THEN i.QuantityChange ELSE 0 END) as TotalImports,
                SUM(CASE WHEN i.ChangeType = 'Export' THEN ABS(i.QuantityChange) ELSE 0 END) as TotalExports,
                MAX(i.CurrentStock) as CurrentStock
            FROM Inventory i
            JOIN Goods g ON i.GoodsID = g.GoodsID
            GROUP BY g.GoodsID
            ORDER BY CurrentStock DESC
        `);
        res.json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Update organization
app.put('/api/organizations/:id', async (req, res) => {
    try {
        const { OrgName, OrgType, Address, City, Country, ContactPerson, Email, Phone } = req.body;
        const [result] = await db.query(
            `UPDATE Organizations 
             SET OrgName = ?, OrgType = ?, Address = ?, City = ?, Country = ?, 
                 ContactPerson = ?, Email = ?, Phone = ?
             WHERE OrgID = ?`,
            [OrgName, OrgType, Address, City, Country, ContactPerson, Email, Phone, req.params.id]
        );
        if (result.affectedRows === 0) {
            res.status(404).json({ error: 'Organization not found' });
            return;
        }
        res.json({ message: 'Organization updated successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Delete organization
app.delete('/api/organizations/:id', async (req, res) => {
    try {
        // Check if organization is referenced in shipments
        const [shipments] = await db.query(
            `SELECT ShipmentID FROM Shipments 
             WHERE OrgID_Supplier = ? OR OrgID_Customer = ? OR OrgID_Logistics = ?`,
            [req.params.id, req.params.id, req.params.id]
        );
        
        if (shipments.length > 0) {
            res.status(400).json({ 
                error: 'Cannot delete organization as it is referenced in shipments' 
            });
            return;
        }

        const [result] = await db.query('DELETE FROM Organizations WHERE OrgID = ?', [req.params.id]);
        if (result.affectedRows === 0) {
            res.status(404).json({ error: 'Organization not found' });
            return;
        }
        res.json({ message: 'Organization deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Update goods
app.put('/api/goods/:id', async (req, res) => {
    try {
        const { Description, HSCode, UnitOfMeasure } = req.body;
        const [result] = await db.query(
            'UPDATE Goods SET Description = ?, HSCode = ?, UnitOfMeasure = ? WHERE GoodsID = ?',
            [Description, HSCode, UnitOfMeasure, req.params.id]
        );
        if (result.affectedRows === 0) {
            res.status(404).json({ error: 'Goods not found' });
            return;
        }
        res.json({ message: 'Goods updated successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Delete goods
app.delete('/api/goods/:id', async (req, res) => {
    try {
        // Check if goods are referenced in shipments
        const [shipmentGoods] = await db.query(
            'SELECT ShipmentID FROM ShipmentGoods WHERE GoodsID = ?',
            [req.params.id]
        );
        
        if (shipmentGoods.length > 0) {
            res.status(400).json({ 
                error: 'Cannot delete goods as they are referenced in shipments' 
            });
            return;
        }

        const [result] = await db.query('DELETE FROM Goods WHERE GoodsID = ?', [req.params.id]);
        if (result.affectedRows === 0) {
            res.status(404).json({ error: 'Goods not found' });
            return;
        }
        res.json({ message: 'Goods deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Update shipment
app.put('/api/shipments/:id', async (req, res) => {
    try {
        const { 
            ShipmentType, ReferenceNumber, OrgID_Supplier, OrgID_Customer,
            DispatchDate, EstimatedArrivalDate, ActualArrivalDate,
            CustomsClearanceDate, CurrentStatus, TotalCost, Currency 
        } = req.body;

        const [result] = await db.query(
            `UPDATE Shipments 
             SET ShipmentType = ?, ReferenceNumber = ?, OrgID_Supplier = ?, 
                 OrgID_Customer = ?, DispatchDate = ?, EstimatedArrivalDate = ?,
                 ActualArrivalDate = ?, CustomsClearanceDate = ?, CurrentStatus = ?,
                 TotalCost = ?, Currency = ?
             WHERE ShipmentID = ?`,
            [
                ShipmentType, ReferenceNumber, OrgID_Supplier || null, 
                OrgID_Customer || null, DispatchDate, EstimatedArrivalDate,
                ActualArrivalDate || null, CustomsClearanceDate || null, 
                CurrentStatus, TotalCost, Currency, req.params.id
            ]
        );
        
        if (result.affectedRows === 0) {
            res.status(404).json({ error: 'Shipment not found' });
            return;
        }
        res.json({ message: 'Shipment updated successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Delete shipment
app.delete('/api/shipments/:id', async (req, res) => {
    try {
        // Delete related records first
        await db.query('DELETE FROM ShipmentGoods WHERE ShipmentID = ?', [req.params.id]);
        await db.query('DELETE FROM ShipmentCosts WHERE ShipmentID = ?', [req.params.id]);
        await db.query('DELETE FROM Documents WHERE ShipmentID = ?', [req.params.id]);
        
        const [result] = await db.query('DELETE FROM Shipments WHERE ShipmentID = ?', [req.params.id]);
        if (result.affectedRows === 0) {
            res.status(404).json({ error: 'Shipment not found' });
            return;
        }
        res.json({ message: 'Shipment deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});

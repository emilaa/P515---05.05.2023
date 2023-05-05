CREATE DATABASE PharmacyDepot;

USE PharmacyDepot;

CREATE TABLE Pharmacies (
  PharmacyID INT PRIMARY KEY,
  PharmacyName NVARCHAR(100),
  Address NVARCHAR(200),
  City NVARCHAR(100),
  [State] NVARCHAR(50),
  ZipCode NVARCHAR(10),
  PhoneNumber NVARCHAR(20)
);

CREATE TABLE Medicines (
  MedicineID INT PRIMARY KEY,
  MedicineName NVARCHAR(100),
  Manufacturer NVARCHAR(100),
  Price DECIMAL(10, 2)
);

CREATE TABLE Depot (
  DepotID INT PRIMARY KEY,
  DepotName NVARCHAR(100),
  [Address] NVARCHAR(200),
  City NVARCHAR(100),
  [State] NVARCHAR(50),
  ZipCode NVARCHAR(10),
  PhoneNumber NVARCHAR(20)
);

CREATE TABLE PharmacyMedicines (
  PharmacyID INT,
  MedicineID INT,
  Quantity INT,
  PRIMARY KEY (PharmacyID, MedicineID),
  FOREIGN KEY (PharmacyID) REFERENCES Pharmacies(PharmacyID),
  FOREIGN KEY (MedicineID) REFERENCES Medicines(MedicineID)
);

CREATE TABLE DepotMedicines (
  DepotID INT,
  MedicineID INT,
  Quantity INT,
  PRIMARY KEY (DepotID, MedicineID),
  FOREIGN KEY (DepotID) REFERENCES Depot(DepotID),
  FOREIGN KEY (MedicineID) REFERENCES Medicines(MedicineID)
);

--VIEW - 1
CREATE VIEW MedicinesReport
AS
SELECT m.MedicineName, m.Price, m.Manufacturer, p.PharmacyName, d.DepotName
FROM Medicines m

LEFT OUTER JOIN PharmacyMedicines pm
ON m.MedicineID = pm.MedicineID

LEFT OUTER JOIN Pharmacies p
ON pm.PharmacyID = p.PharmacyID

LEFT OUTER JOIN DepotMedicines dm
ON m.MedicineID = dm.MedicineID

LEFT OUTER JOIN Depot d
ON dm.DepotID = d.DepotID

SELECT * FROM dbo.MedicinesReport

--VIEW - 2
CREATE VIEW LowQuantityMedicines
AS
SELECT 
m.MedicineName, 
m.Price, 
m.Manufacturer, 
p.PharmacyName, 
pm.Quantity AS InPharmacyQuantity, 
d.DepotName, 
dm.Quantity AS InDepotQuantity
FROM Medicines m

LEFT OUTER JOIN PharmacyMedicines pm
ON m.MedicineID = pm.MedicineID

LEFT OUTER JOIN Pharmacies p
ON pm.PharmacyID = p.PharmacyID

LEFT OUTER JOIN DepotMedicines dm
ON m.MedicineID = dm.MedicineID

LEFT OUTER JOIN Depot d
ON dm.DepotID = d.DepotID

WHERE pm.Quantity < 10

SELECT * FROM dbo.LowQuantityMedicines

--PROCEDURE - 3
CREATE PROCEDURE UpdateMedicineQuantity @Id int
AS
UPDATE PharmacyMedicines
SET Quantity = Quantity + 100
WHERE MedicineID = @Id AND Quantity < 10

EXEC dbo.UpdateMedicineQuantity 1

--PROCEDURE - 4
CREATE PROCEDURE DataTransfer @MedicineId int, @PharmacyID int
AS
UPDATE PharmacyMedicines
SET PharmacyID = @PharmacyID
WHERE MedicineID = @MedicineId

EXEC dbo.DataTransfer 1, 1

--FUNCTION - 5
CREATE FUNCTION MedicineQuantityAvgByZipCode(@zipcode int)
RETURNS int
AS
BEGIN
DECLARE @Avg int
SELECT @Avg = AVG(Quantity) FROM PharmacyMedicines pm
JOIN Pharmacies p
ON pm.PharmacyID = p.PharmacyID
WHERE p.ZipCode = @zipcode
RETURN @Avg
END

SELECT dbo.MedicineQuantityAvgByZipCode(11)

DECLARE @currentCity VARCHAR(100) = 'Baku';
DECLARE @transferCity VARCHAR(100) = 'Ganja';
DECLARE @numberOfDrugsTransferred INT;

UPDATE dm
SET DepotId = transfer_depot.DepotId
OUTPUT inserted.MedicineId, inserted.Quantity
FROM DepotMedicines dm
JOIN Depot current_depot ON dm.DepotId = current_depot.DepotId
JOIN Depot transfer_depot ON transfer_depot.City = @transferCity
WHERE current_depot.City = @currentCity;

SELECT @numberOfDrugsTransferred = SUM(Quantity)
FROM DepotMedicines dm
JOIN Depot transfer_depot ON dm.DepotId = transfer_depot.DepotId
WHERE transfer_depot.City = @transferCity;

SELECT 'Transferred medicines sum: ' + CAST(@numberOfDrugsTransferred AS NVARCHAR(10)) AS [Result];



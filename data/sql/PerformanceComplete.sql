USE warpshop;

CREATE TABLE Customer (
ID INT PRIMARY KEY,
fName VARCHAR(256),
lName VARCHAR(256),
bDate DATE,
custSince DATE,
eMail VARCHAR(256),
street VARCHAR(256),
hsnr VARCHAR(16),
plz CHAR(5),
city VARCHAR(128),
gender CHAR(1),
buLa VARCHAR(64),
tel VARCHAR(32));

CREATE TABLE Product (
ID INT PRIMARY KEY,
Name VARCHAR(512),
ModelNumber VARCHAR(256),
weight DECIMAL(9,2),
size VARCHAR(64));

CREATE TABLE Categories (
ID INT PRIMARY KEY AUTO_INCREMENT,
ProductID INT NOT NULL,
category VARCHAR(256) NOT NULL,
FOREIGN KEY (ProductID) REFERENCES Product(ID));

CREATE TABLE Images (
ID INT PRIMARY KEY AUTO_INCREMENT,
ProductID INT NOT NULL,
name VARCHAR(128) NOT NULL,
FOREIGN KEY (ProductID) REFERENCES Product(ID));

CREATE TABLE ProdInfo (
ID INT PRIMARY KEY AUTO_INCREMENT,
ProductID INT NOT NULL,
info VARCHAR(1024) NOT NULL,
FOREIGN KEY (ProductID) REFERENCES Product(ID));

CREATE TABLE ProdSpec (
ID INT PRIMARY KEY AUTO_INCREMENT,
ProductID INT NOT NULL,
spec TEXT NOT NULL,
FOREIGN KEY (ProductID) REFERENCES Product(ID));

CREATE TABLE ProdTecSpec (
ID INT PRIMARY KEY AUTO_INCREMENT,
ProductID INT NOT NULL,
tecSpec TEXT NOT NULL,
FOREIGN KEY (ProductID) REFERENCES Product(ID));


CREATE TABLE ProductPrice (
ID INT PRIMARY KEY AUTO_INCREMENT,
fromDate DATE,
ProductId INT,
Price DECIMAL(8,2),
FOREIGN KEY (ProductId) REFERENCES Product(ID));


CREATE TABLE CustOrder (
ID INT PRIMARY KEY,
CustomerId INT,
OrderDate DATE,
FOREIGN KEY (CustomerId) REFERENCES Customer(ID));


CREATE TABLE OrderElement(
ID INT PRIMARY KEY AUTO_INCREMENT,
OrderID INT,
ProductID INT,
Quantity INT,
FOREIGN KEY (OrderID) REFERENCES CustOrder(ID),
FOREIGN KEY (ProductID) REFERENCES Product(ID));


LOAD DATA INFILE '/etc/mysql/csv_files/Customer_testdata.csv' 
INTO TABLE Customer 
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\r\n'
(ID, fName, lName, bDate, custSince, eMail, street, hsnr, plz, city, gender, buLa, tel);

LOAD DATA INFILE '/etc/mysql/csv_files/Product_testdata.csv' 
INTO TABLE Product 
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\r\n'
(ID, Name, ModelNumber, weight, size);

LOAD DATA INFILE '/etc/mysql/csv_files/Categories_testdata.csv' 
INTO TABLE Categories 
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\r\n'
(ID, ProductId, category);

LOAD DATA INFILE '/etc/mysql/csv_files/Images_testdata.csv' 
INTO TABLE Images 
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\r\n'
(ID, ProductId, name);

LOAD DATA INFILE '/etc/mysql/csv_files/ProdInfo_testdata.csv' 
INTO TABLE ProdInfo 
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\r\n'
(ID, ProductId, info);

LOAD DATA INFILE '/etc/mysql/csv_files/ProdSpec_testdata.csv' 
INTO TABLE ProdSpec 
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\r\n'
(ID, ProductId, spec);

LOAD DATA INFILE '/etc/mysql/csv_files/ProdTecSpec_testdata.csv' 
INTO TABLE ProdTecSpec 
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\r\n'
(ID, ProductId, tecSpec);

LOAD DATA INFILE '/etc/mysql/csv_files/ProductPrice_testdata.csv' 
INTO TABLE ProductPrice 
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\r\n'
(ID, fromDate, ProductId, Price);

LOAD DATA INFILE '/etc/mysql/csv_files/CustOrder_testdata.csv' 
INTO TABLE CustOrder 
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\r\n'
(ID, CustomerId, OrderDate);

LOAD DATA INFILE '/etc/mysql/csv_files/OrderElement_testdata.csv' 
INTO TABLE OrderElement 
FIELDS TERMINATED BY '|'
LINES TERMINATED BY '\r\n'
(ID, OrderID, ProductID, quantity);

CREATE VIEW price1 AS
SELECT *, COALESCE(
  (SELECT DATE_SUB(MIN(fromDate), INTERVAL 1 DAY) FROM ProductPrice 
    WHERE ProductID = pp.ProductID
      AND fromDate > pp.fromDate)
, "9999-01-01") AS toDate
 FROM ProductPrice pp;

CREATE VIEW price2 AS
SELECT p1.*, COALESCE(DATE_SUB(MIN(p2.fromDate), INTERVAL 1 DAY), "9999-01-01") AS toDate
FROM ProductPrice p1 
LEFT OUTER JOIN ProductPrice p2 ON 
  (p1.ProductID = p2.ProductID AND p1.fromDate < p2.fromDate)
GROUP BY p1.ID;

CREATE TABLE ProdPriceFromToMat (
ID INT PRIMARY KEY,
ProductID INT NOT NULL,
Price DECIMAL(8,2) NOT NULL,
fromDate DATE,
toDate DATE
);

CREATE INDEX id_PrductIdMat ON ProdPriceFromToMat(ProductID);
CREATE INDEX id_fromDateMat ON ProdPriceFromToMat(fromDate);
CREATE INDEX id_toDateMat ON ProdPriceFromToMat(toDate);

INSERT INTO ProdPriceFromToMat (ID, ProductID, Price, fromDate, toDate)
SELECT ID, ProductID, Price, fromDate, toDate FROM price1;

DELIMITER $$
CREATE TRIGGER INS_ProdPriceFromToMat BEFORE INSERT ON ProductPrice
	FOR EACH ROW BEGIN
		UPDATE ProdPriceFromToMat SET toDate = 
		  DATE_SUB(NEW.fromDate, INTERVAL 1 DAY) 
		WHERE ProductID = NEW.ProductId
		  AND fromDate = (SELECT MAX(fromDate) FROM ProductPrice 
						 WHERE ProductID = NEW.ProductID);
		INSERT INTO ProdPriceFromToMat SET 
		ID = NEW.ID,
		ProductID = NEW.ProductID,
		Price = NEW.Price,
		fromDate = NEW.fromDate,
		toDate = '9999-01-01';
	END$$
DELIMITER ;


DROP DATABASE IF EXISTS insurance_property;
CREATE DATABASE insurance_property;

USE insurance_property;

CREATE TABLE buildings (
  id INT PRIMARY KEY AUTO_INCREMENT,
  floors INT,
  materials VARCHAR(255),
  color VARCHAR(255),
  area DECIMAL(10, 2),
  has_terrace BOOLEAN,
  address VARCHAR(255),
  postal_code VARCHAR(10),
  latitude FLOAT,
  longitude FLOAT
);

CREATE TABLE owners (
  id INT PRIMARY KEY AUTO_INCREMENT,
  first_name VARCHAR(255),
  middle_name VARCHAR(255),
  last_name VARCHAR(255),
  egn VARCHAR(10),
  email VARCHAR(255),
  phone_number VARCHAR(20),
  address VARCHAR(255),
  annual_income DECIMAL(10, 2),
  is_married BOOLEAN
);

CREATE TABLE policies (
  id INT PRIMARY KEY AUTO_INCREMENT,
  start_date DATE,
payment_amount FLOAT NOT NULL,
payment_due_date DATE NOT NULL,
reimbursement_amount FLOAT NOT NULL,
  building_id INT,
  owner_id INT,
  FOREIGN KEY (building_id) REFERENCES buildings(id),
  FOREIGN KEY (owner_id) REFERENCES owners(id)
);

CREATE TABLE building_owner (
  building_id INT NOT NULL,
  owner_id INT NOT NULL,
  PRIMARY KEY (building_id, owner_id),
  FOREIGN KEY (building_id) REFERENCES buildings(id) ON DELETE CASCADE,
  FOREIGN KEY (owner_id) REFERENCES owners(id) ON DELETE CASCADE
);


INSERT INTO buildings (floors, materials, color, area, has_terrace, address, postal_code, latitude, longitude)
VALUES
(4, 'concrete', 'white', 250.50, true, 'Kv.Charodeika 436', '1606', 40.7532, -73.9862),
(2, 'brick', 'black', 120.75, false, 'Aleksandar Ekzarh 2', '4000', 40.7178, -73.9973),
(6, 'steel', 'green', 500.00, true, 'Oborishte 8', '1504', 40.7644, -73.9737),
(3, 'concrete', 'blue', 150.25, false, 'Vitosha 6', '1000', 40.7068, -74.0113);

INSERT INTO owners (first_name, middle_name, last_name, egn, email, phone_number, address, annual_income, is_married)
VALUES
('Emiliyan', 'Marinov', 'Bochev', '1234567890', 'e.bochev@gmail.com', '087-456-7890', 'Kv.Charodeika 436', 18700.00, true),
('Sofiya', "Davidova", 'Ivanova', '0987654321', 's.ivanova@gmail.com', '088-654-3210', 'Aleksandar Ekzarh 2',
 20000.00, false),
('Atanas', 'Rumenov', 'Donev', '2468013579', 'a.donn@gmail.com', '088-555-5555', 'Oborishte 8', 22500.00, true),
('Zornitsa', 'Koleva', 'Borisova', '1357902468', 'zornitsa.borisova@gmail.com', '087-111-1111', 'Vitosha 6', 
19600.00, false);

INSERT INTO policies (start_date, payment_amount, payment_due_date, reimbursement_amount, building_id, owner_id)
VALUES
('2019-11-14', 1000.00, '2019-11-12', 5000.00, 1, 1),
('2017-04-14', 750.00, '2018-04-12', 3000.00, 2, 2),
('2022-01-05', 1500.00, '2022-12-04', 7500.00, 3, 3),
('2020-02-25', 500.00, '2020-02-24', 2500.00, 4, 4);


#3
SELECT materials, AVG(area) AS avg_area
FROM buildings
GROUP BY materials;

#4
SELECT owners.first_name, owners.last_name, buildings.address, buildings.area
FROM owners
INNER JOIN policies ON owners.id = policies.owner_id
INNER JOIN buildings ON policies.building_id = buildings.id
WHERE buildings.materials = 'concrete';

#5
SELECT buildings.id, buildings.address, policies.id AS policy_id
FROM buildings
LEFT OUTER JOIN policies
ON buildings.id = policies.building_id;

#6
SELECT 
    o.first_name,
    o.last_name,
    o.egn,
    o.email,
    o.phone_number
FROM 
    owners o
WHERE 
    o.id IN (
        SELECT 
            p.owner_id
        FROM 
            policies p
            INNER JOIN buildings b ON p.building_id = b.id
        WHERE 
            p.start_date BETWEEN '2022-01-01' AND '2022-12-31'
            AND p.payment_amount > 1000
    ) // dava gi i atanas i emiliyan???
    
    

#7
SELECT owners.first_name, 
AVG(policies.payment_amount) AS average_payment, COUNT(policies.id) AS policy_count
FROM owners
JOIN policies ON owners.id = policies.owner_id
WHERE owners.is_married = true
GROUP BY owners.first_name;

#8
DELIMITER //
CREATE TRIGGER zero_reimbursement
BEFORE INSERT ON policies
FOR EACH ROW
BEGIN
    IF NEW.payment_amount <= 500 THEN
        SET NEW.reimbursement_amount = 0;
    END IF;
END//
DELIMITER ;

UPDATE policies SET payment_amount = 450 WHERE id = 2;

SELECT * FROM policies WHERE id = 2;



#za vtoro uslovie po-slozna zajavka
SELECT owners.first_name, owners.last_name, owners.email,
 owners.phone_number, owners.annual_income, buildings.area
FROM owners
INNER JOIN policies ON owners.id = policies.owner_id
INNER JOIN buildings ON policies.building_id = buildings.id
WHERE owners.annual_income > 20000.00 AND buildings.area > 200.00;

SELECT first_name, last_name
FROM owners
JOIN policies
ON owners.id = policies.owner_id
WHERE first_name LIKE '%YA%' AND annual_income > 19000.00;



#8
CREATE TRIGGER update_policy_amount
AFTER INSERT ON policies
FOR EACH ROW
BEGIN
  UPDATE owners
  SET annual_income = annual_income + NEW.payment_amount
  WHERE owners.id = NEW.owner_id;
END;

SELECT first_name, last_name, email, egn, phone_number
FROM owners
WHERE id IN (
  SELECT owner_id
  FROM policies
  WHERE start_date BETWEEN '2022-01-01' AND '2022-12-31'
  AND payment_amount > 1000
  AND owner_id IN (
    SELECT owner_id
    FROM building_owner
    WHERE building_id IN (
      SELECT id
      FROM buildings
    )
  )
);

USE insurance_property;

DROP PROCEDURE IF EXISTS `get_building_owners`;

DELIMITER $$

CREATE PROCEDURE `get_building_owners`(IN building_id INT)
BEGIN
    SELECT owners.first_name, owners.last_name
    FROM owners
    JOIN building_owner ON owners.id = building_owner.owner_id
    WHERE building_owner.building_id = building_id;
END $$

DELIMITER ;

USE insurance_property;
DROP PROCEDURE IF EXISTS get_buildings_with_terrace;

DELIMITER //
CREATE PROCEDURE get_buildings_with_terrace()
BEGIN
  DECLARE done INT DEFAULT FALSE;
  DECLARE bldg_id INT;
  DECLARE bldg_address VARCHAR(255);
  DECLARE bldg_has_terrace BOOLEAN;

  DECLARE cur CURSOR FOR SELECT id, address, has_terrace FROM buildings;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
  CREATE TEMPORARY TABLE IF NOT EXISTS temp_buildings (
    id INT,
    address VARCHAR(255)
  );

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO bldg_id, bldg_address, bldg_has_terrace;
    IF done THEN
      LEAVE read_loop;
    END IF;
IF bldg_has_terrace THEN
      INSERT INTO temp_buildings VALUES (bldg_id, bldg_address);
    END IF;
  END LOOP;
  SELECT CONCAT('Building ID: ', id, ' - Address: ', address) AS Building_With_Terrace 
    FROM temp_buildings;

  CLOSE cur;
END //
DELIMITER ;

CALL get_buildings_with_terrace();













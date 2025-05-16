USE ORDER_DDS;
GO

-- Insert new unique supplier profiles
INSERT INTO Dim_Suppliers_Profile (
    phone,
    fax,
    homepage
)
SELECT DISTINCT
    Phone,
    Fax,
    HomePage
FROM stg_raw_Suppliers s
WHERE NOT EXISTS (
    SELECT 1
    FROM Dim_Suppliers_Profile p
    WHERE p.phone = s.Phone
      AND p.fax = s.Fax
      AND p.homepage = s.HomePage
);

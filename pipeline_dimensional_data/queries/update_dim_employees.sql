USE ORDER_DDS;
GO

DECLARE @start_date DATE;
DECLARE @end_date DATE;

DECLARE @sor_sk INT;
SELECT @sor_sk = sor_sk 
FROM Dim_SOR 
WHERE staging_table_name = 'Staging_Employees';

MERGE DimEmployees AS target
USING Staging_Employees AS source
ON target.employee_id_nk = source.EmployeeID
WHEN MATCHED AND (
    target.last_name           != source.LastName OR
    target.first_name          != source.FirstName OR
    target.title               != source.Title OR
    target.title_of_courtesy  != source.TitleOfCourtesy OR
    target.birth_date          != source.BirthDate OR
    target.hire_date           != source.HireDate OR
    target.address             != source.Address OR
    target.city                != source.City OR
    target.region              != source.Region OR
    target.postal_code         != source.PostalCode OR
    target.country             != source.Country OR
    target.home_phone          != source.HomePhone OR
    target.extension           != TRY_CAST(source.Extension AS INT) OR
    target.notes               != source.Notes OR
    target.reports_to          != source.ReportsTo OR
    target.photo_path          != source.PhotoPath
)
THEN UPDATE SET
    last_name          = source.LastName,
    first_name         = source.FirstName,
    title              = source.Title,
    title_of_courtesy  = source.TitleOfCourtesy,
    birth_date         = source.BirthDate,
    hire_date          = source.HireDate,
    address            = source.Address,
    city               = source.City,
    region             = source.Region,
    postal_code        = source.PostalCode,
    country            = source.Country,
    home_phone         = source.HomePhone,
    extension          = TRY_CAST(source.Extension AS INT),
    notes              = source.Notes,
    reports_to         = source.ReportsTo,
    photo_path         = source.PhotoPath,
    staging_raw_id_sk  = source.Staging_Raw_ID,
    sor_sk             = @sor_sk
WHEN NOT MATCHED BY TARGET
THEN INSERT (
    employee_id_nk,
    last_name,
    first_name,
    title,
    title_of_courtesy,
    birth_date,
    hire_date,
    address,
    city,
    region,
    postal_code,
    country,
    home_phone,
    extension,
    notes,
    reports_to,
    photo_path,
    staging_raw_id_sk,
    sor_sk
)
VALUES (
    source.EmployeeID,
    source.LastName,
    source.FirstName,
    source.Title,
    source.TitleOfCourtesy,
    source.BirthDate,
    source.HireDate,
    source.Address,
    source.City,
    source.Region,
    source.PostalCode,
    source.Country,
    source.HomePhone,
    TRY_CAST(source.Extension AS INT),
    source.Notes,
    source.ReportsTo,
    source.PhotoPath,
    source.Staging_Raw_ID,
    @sor_sk
);

DELETE FROM DimEmployees
WHERE employee_id_nk NOT IN (
    SELECT EmployeeID FROM Staging_Employees
);
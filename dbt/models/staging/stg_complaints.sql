with source as (
    select * from {{ source('bronze', 'complaints') }}
),

renamed as (
    select
        -- IDs
        cast("odiNumber" as bigint) as odi_number,
     
        
        -- Manufacturer info
        manufacturer,

        -- Vehicle info
        vin,
        
        -- Dates
        strptime("dateOfIncident", '%m/%d/%Y')::date as date_of_incident,
        strptime("dateComplaintFiled", '%m/%d/%Y')::date as date_complaint_filed,
        
        -- Recall details
        components,
        summary,
        products,
        
        -- Complaint Severity details
        crash,
        fire,
        cast("numberOfInjuries" as integer) as number_of_injuries,
        cast("numberOfDeaths" as integer) as number_of_deaths,

        -- Ingestion metadata
        "_source_url" as source_url,
        cast("_response_status" as integer) as response_status,
        cast("_ingested_at" as timestamp) as ingested_at,
        ingest_date -- from Hive partitioning
    from source
)

select * from renamed
with source as (
    select * from {{ source('bronze', 'recalls') }}
),

renamed as (
    select
        -- IDs
        "NHTSACampaignNumber" as campaign_number,
        "NHTSAActionNumber" as action_number,
        
        -- Manufacturer info
        "Manufacturer" as manufacturer,
        
        -- Dates
        strptime("ReportReceivedDate", '%d/%m/%Y')::date as report_received_date,
        
        -- Vehicle info
        "Make" as make,
        "Model" as model,
        cast("ModelYear" as integer) as model_year,
        
        -- Recall details
        "Component" as component,
        "Summary" as summary,
        "Consequence" as consequence,
        "Remedy" as remedy,
        "Notes" as notes,
        
        -- Severity flags (already boolean in JSON)
        "parkIt" as park_it,
        "parkOutSide" as park_outside,
        "overTheAirUpdate" as over_the_air_update,
        
        -- Ingestion metadata
        "_source_url" as source_url,
        cast("_response_status" as integer) as response_status,
        cast("_ingested_at" as timestamp) as ingested_at,
        ingest_date -- from Hive partitioning
    from source
)

select * from renamed
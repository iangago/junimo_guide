# 🌱 Junimo Guide

A data engineering project inspired by *Stardew Valley*, focused on building a structured data platform for game knowledge, analytics, and a future AI-powered assistant.

## About the Project

Junimo Guide is a personal data engineering project built around *Stardew Valley*, a farming and life simulation game.

While playing, players often need to leave the game to search the Wiki, Google, or YouTube for information about items, crops, recipes, and resources.

The long-term idea is to make this information accessible through a single platform, eventually allowing players to ask questions in natural language without interrupting their gameplay.

Before building the assistant, however, the project focuses on the underlying data problem:

**How can data from different external sources be ingested, cleaned, reconciled, and transformed into reliable information that can support analytics and applications?**

The project is being developed incrementally, starting with a crop profitability pipeline before expanding to other game entities.

---

## Core Idea

Junimo Guide is primarily a **data engineering project**, with analytics as an initial use case and an AI assistant as a future application.

The first implementation focuses on crops, using two external Stardew Valley datasets to build a reproducible data pipeline.

Rather than relying on a single source, the project brings together data from different sources, allowing inconsistencies and differences in structure to be addressed during processing.

The initial scope covers:

* ingesting external JSON data
* preserving raw data in a Bronze layer
* cleaning and reconciling data in Silver
* generating analytical datasets in Gold
* storing structured data in PostgreSQL
* transforming and testing data with dbt
* analyzing crop profitability and return on investment (ROI)

The broader goal is to establish a reliable data foundation that can eventually support more complex queries and an AI assistant.

---

## Features

### Data Ingestion

* Ingest crop data from two external sources
* Process JSON input files
* Preserve ingested data in the Bronze layer
* Separate ingestion from downstream transformations

### Data Cleaning and Reconciliation

* Clean and normalize data from different sources
* Standardize information for downstream processing
* Reconcile data between the two sources
* Prepare structured data for relational storage

### Medallion Architecture

The pipeline is organized into three layers:

* **Bronze:** raw ingested data
* **Silver:** cleaned and reconciled data
* **Gold:** analytical data derived from the previous layers

### Crop Profitability Analysis

The Gold layer provides derived crop profitability information, including ROI-oriented analysis.

This creates an initial analytical use case for the data platform while validating the transformation pipeline.

### Data Quality

The project uses dbt to manage transformations and execute configured data quality tests.

### Reproducible Pipeline

The Crops pipeline can be run from scratch by preparing the required raw input files, creating the PostgreSQL database, running ingestion, and executing the dbt transformations.

---

## Data Pipeline

The current pipeline follows this structure:

```text
      External Data Sources
          JSON Files
               |
               v
           Ingestion
               |
               v
            BRONZE
          Raw Data
               |
               v
             SILVER
     Cleaned and Reconciled
               |
               v
              GOLD
      Crop Profitability
           Analysis
               |
               v
          PostgreSQL
```

The architecture separates raw ingestion from data transformation and analytical modeling.

This makes it possible to preserve the original inputs, process them into a consistent representation, and derive analytical outputs without treating every stage as the same dataset.

---

## Data Sources

The project currently uses two external sources of Stardew Valley data.

### Primary Source: Stardew Data

Repository: https://github.com/juliaramosguedes/stardew-data

This project extracts structured data directly from Stardew Valley's game files.

It serves as the primary source for the current implementation.

### Secondary Source: Stardew Valley Data

Repository: https://github.com/chiefpansancolt/stardew-valley-data

This repository provides a structured community dataset containing Stardew Valley information.

It serves as a secondary source for comparison, validation, and reconciliation.

Both sources are used as inputs to Junimo Guide's own pipeline. Their existing extraction and lookup implementations are not the core of this project.

---

## Working with External Data

The project uses existing datasets rather than generating game data from scratch.

The engineering work focuses on what happens after those datasets become inputs to the pipeline.

Using multiple sources introduces challenges that must be addressed during processing, including differences in structure, field availability, identifiers, and consistency.

The Silver layer is responsible for preparing a cleaner and more consistent representation of the ingested data.

The Gold layer then uses the processed data to support a specific analytical use case: crop profitability.

This approach reflects the project's central objective of practicing data ingestion, transformation, reconciliation, and modeling with real external data.

---

## Tech Stack

| Category             | Technology             |
| -------------------- | ---------------------- |
| Programming Language | Python                 |
| Database             | PostgreSQL             |
| Data Transformation  | dbt                    |
| Input Format         | JSON                   |
| Architecture         | Medallion Architecture |
| Version Control      | Git / GitHub           |

---

## Installation

### Prerequisites

* Python
* PostgreSQL
* dbt
* Git

### 1. Clone the Repository and Install Requirements

```bash
git clone <repository-url>
cd junimo-guide
```

In your project folder terminal, run:
```bash
pip install -r requirements.txt
```

### 2. Create the Database

Create a PostgreSQL database named:

```sql
CREATE DATABASE junimo_db;
```

### 3. Configure the Database Connection

Configure the database credentials and connection settings required by the project.

Credentials should be stored local file created by the user named `config.py`, rather than committed to the repository.

`config.py` structure:

```python
# -*- coding: utf-8 -*-
DB_HOST = YOUR_HOST
DB_PORT = YOUR_PORT
DB_NAME = "junimo_db"
DB_USER = YOUR_USER
DB_PASSWORD = YOUR_PASSWORD
```

### 4. Prepare the Raw Data

Obtain the required crop JSON files from both external sources and place them in:

```text
data/raw/
```

The files must follow the input structure expected by the ingestion pipeline.

### 5. Run the Pipeline

Run the project's ingestion entry point to process the raw files and populate the Bronze layer.

```text
python src/ingestion/ingestion.py 
```

Then execute the configured dbt transformations to build the Silver and Gold layers.

Silver:
```text
python -m dbt.cli.main run --project-dir junimo_dbt --profiles-dir junimo_dbt --select crops --full-refresh  
```

Gold:
```text
python -m dbt.cli.main run --project-dir junimo_dbt --profiles-dir junimo_dbt --select agent_crops --full-refresh
```

Run the dbt tests to validate the configured data quality rules.

The exact commands depend on the project's current script and dbt configuration.

---

## Project Status

**In active development — Crops pipeline implemented.**

The Crops pipeline is the first completed proof of concept and can be reproduced from the raw input files.

The current implementation covers:

* external data ingestion
* Bronze layer creation
* Silver transformations and source reconciliation
* PostgreSQL storage
* dbt transformations and tests
* Gold analytical modeling
* crop profitability and ROI analysis

The broader knowledge platform and AI assistant have not yet been implemented.

Development is proceeding incrementally, using the Crops pipeline to establish the initial data engineering workflow before expanding to additional entities.

---

## What I Learned

This project is being developed as a hands-on exercise in data engineering.

The current implementation provides practical experience with:

### Data Ingestion

* working with external JSON datasets
* separating raw inputs from processed data
* designing a reproducible ingestion workflow

### Data Engineering

* implementing Bronze, Silver, and Gold layers
* cleaning and standardizing data
* reconciling multiple sources
* preparing data for downstream use

### Database and Transformation

* storing structured data in PostgreSQL
* managing transformations with dbt
* organizing analytical models
* testing data quality

### Analytical Modeling

* deriving profitability metrics from structured data
* preparing transformed data for analytical use cases
* separating cleaned data from business-oriented calculations

The project emphasizes the data lifecycle rather than treating the final analytical output as the entire solution.

---

## Limitations

The current implementation has a deliberately limited scope.

* The implemented pipeline focuses on crops rather than the entire game.
* The pipeline depends on external datasets and their available information.
* Differences between sources must be handled during reconciliation.
* The current Gold layer focuses on crop profitability and ROI.
* The AI assistant and its query tools are future components, not implemented features.

The current pipeline should therefore be understood as an initial data platform proof of concept, not a complete Stardew Valley knowledge system.

---

## Future Development

The next stages will expand the data platform before introducing the AI assistant.

Potential additions include:

* **Items:** structured information about game items
* **Item sources:** where and how items can be obtained
* **Recipes:** crafting and cooking recipes
* **Ingredients:** relationships between recipes and required items
* **Query tools:** deterministic functions that retrieve information from PostgreSQL
* **AI assistant:** a natural-language interface grounded in the project's data

The intended direction is to keep structured data as the source of truth and use the AI to interpret questions, retrieve relevant information, and explain the results.

---

## Author

**Ian Gago Mendes**

import os
import traceback
from datetime import datetime
from typing import Dict, Any, Optional, List
import logging
from dataclasses import dataclass

from google.cloud import bigquery
from google.cloud.exceptions import GoogleCloudError
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("mma_coordinator")

@dataclass
class FighterData:
    id: str
    name: str
    weight_class: str
    fight_history: List[Dict[str, Any]]
    injury_history: List[Dict[str, Any]]

class BigQueryService:
    """Service class for BigQuery operations with retry logic."""
    
    def __init__(self, project_id: str):
        self.client = bigquery.Client()
        self.project_id = project_id
        self.dataset_id = f"{project_id}.mma_analysis"
        self.read_only = False
        
    def initialize_dataset(self) -> None:
        """Initialize BigQuery dataset with error handling."""
        try:
            dataset = bigquery.Dataset(self.dataset_id)
            dataset.location = "US"
            dataset.description = "MMA fighter analysis and injury prediction data"
            self.client.create_dataset(dataset, exists_ok=True)
        except Exception as e:
            logger.warning(f"Could not create dataset (may already exist): {str(e)}")
            # Verify we can at least access the dataset
            try:
                self.client.get_dataset(self.dataset_id)
                logger.info(f"Confirmed access to dataset {self.dataset_id}")
            except Exception as e:
                logger.error(f"Cannot access dataset {self.dataset_id}: {str(e)}")
                raise
        
    def create_metrics_table(self) -> None:
        """Create fight metrics table with proper schema."""
        schema = [
            bigquery.SchemaField("fighter_id", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("timestamp", "TIMESTAMP", mode="REQUIRED"),
            bigquery.SchemaField("risk_score", "FLOAT", mode="REQUIRED"),
            bigquery.SchemaField("joint_angles", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("weight_class", "STRING", mode="REQUIRED"),
            bigquery.SchemaField("fight_count", "INTEGER", mode="REQUIRED"),
            bigquery.SchemaField("injury_count", "INTEGER", mode="REQUIRED")
        ]
        
        table = bigquery.Table(f"{self.dataset_id}.fight_metrics", schema=schema)
        table.time_partitioning = bigquery.TimePartitioning(
            type_=bigquery.TimePartitioningType.DAY,
            field="timestamp"
        )
        self.client.create_table(table, exists_ok=True)
        
    def train_injury_model(self, training_query: str) -> None:
        """Train injury prediction model with proper error handling."""
        job = self.client.query(training_query)
        job.result()  # Wait for completion
        logger.info(f"Injury prediction model trained in {self.dataset_id}")

class FightCoordinator:
    """Coordinator agent that orchestrates the MMA analysis pipeline."""
    
    def __init__(self):
        load_dotenv()
        project_id = os.getenv('GCP_PROJECT_ID')
        if not project_id:
            raise ValueError("GCP_PROJECT_ID environment variable not set")
            
        self.bq_service = BigQueryService(project_id)
        self._init_bigquery()
        
    def _init_bigquery(self) -> None:
        """Initialize BigQuery resources with proper error handling."""
        try:
            self.bq_service.initialize_dataset()
            self.bq_service.create_metrics_table()
            
            # Example training query - should be replaced with real data
            training_query = f"""
            CREATE OR REPLACE MODEL `{self.bq_service.dataset_id}.injury_predictor`
            OPTIONS(
                MODEL_TYPE='LOGISTIC_REG',
                INPUT_LABEL_COLS=['injury_occurred'],
                AUTO_CLASS_WEIGHTS=TRUE
            ) AS
            SELECT
                risk_score,
                weight_class,
                fight_count,
                injury_count,
                CASE WHEN risk_score > 0.7 THEN TRUE ELSE FALSE END AS injury_occurred
            FROM
                `{self.bq_service.dataset_id}.fight_metrics`
            WHERE
                timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 YEAR)
            """
            self.bq_service.train_injury_model(training_query)
            
        except GoogleCloudError as e:
            logger.error(f"BigQuery initialization failed: {e}")
            raise

    def process_fight(self, video_uri: str, fighter_data: FighterData) -> Dict[str, Any]:
        """Process a fight video through the analysis pipeline.
        
        Args:
            video_uri: URI of the fight video to analyze
            fighter_data: Fighter metadata and history
            
        Returns:
            Dictionary containing analysis results and predictions
        """
        return {
            "status": "not_implemented",
            "message": "Video analysis pipeline not yet implemented"
        }

if __name__ == "__main__":
    try:
        coordinator = FightCoordinator()
        print("FightCoordinator initialized successfully")
    except Exception as e:
        print(f"Failed to initialize FightCoordinator: {str(e)}")
        print("Some features may not be available")

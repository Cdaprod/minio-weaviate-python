# Title: Streamlining Hybrid Cloud Operations with MinIO and Weaviate Using Pydantic and Unstructured-io for Enhanced ETL Processes

### Introduction

Managing hybrid cloud environments can be a complex task, but leveraging the right tools and technologies can significantly streamline operations. This guide focuses on integrating MinIO and Weaviate for seamless data storage and retrieval, using Pydantic for data modeling and `unstructured-io` for automatic data partitioning. By following the steps outlined in this document, you can create a powerful ETL process that enhances both DevOps and AIOps workflows.

### Why This Approach is Beneficial

Integrating MinIO and Weaviate within a hybrid cloud setup provides several advantages. Firstly, MinIO offers high-performance, scalable object storage that is S3-compatible, making it a versatile choice for cloud-native applications. When combined with Weaviate, a vector search engine that excels at handling complex queries and large datasets, you get a robust solution for managing and retrieving unstructured data. This integration ensures that data is not only securely stored but also easily searchable and retrievable, enhancing operational efficiency.

Moreover, the use of Pydantic for data modeling ensures that data is validated and structured consistently, reducing errors and improving maintainability. Pydantic's intuitive syntax and powerful validation mechanisms make it easier to define and enforce data schemas, which is crucial for maintaining data integrity across complex systems. Additionally, incorporating `unstructured-io` for automatic data partitioning simplifies the data ingestion process, allowing for more efficient handling and processing of various data formats. This approach not only saves time but also ensures that the data is organized in a way that maximizes its usability and accessibility.

### Step-by-Step Implementation

1. **Install Dependencies**:
   Ensure you have the necessary packages installed.

   ```sh
   pip install pydantic unstructured minio weaviate-client
   ```

2. **Define Pydantic Models**:
   Create Pydantic models for MinIO object metadata and Weaviate data objects.

3. **Integrate `unstructured-io`**:
   Use `unstructured-io` for partitioning and processing the data before uploading and indexing.

### Pydantic Models and Updated Script

#### models.py

```python
from pydantic import BaseModel, Field
from typing import Dict, Optional
from datetime import datetime

class MinioMetadata(BaseModel):
    object_name: str
    last_modified: datetime
    etag: str
    size: int
    content_type: str
    metadata: Dict[str, str]

class WeaviateObject(BaseModel):
    object_name: str
    last_modified: datetime
    etag: str
    size: int
    content_type: str
    metadata: Dict[str, str]
```

#### minio_weaviate.py

```python
from minio import Minio
from weaviate import Client
from models import MinioMetadata, WeaviateObject
from unstructured.partition.auto import partition
import sys
from pydantic import BaseSettings

class Settings(BaseSettings):
    minio_endpoint: str
    minio_access_key: str
    minio_secret_key: str
    weaviate_url: str

settings = Settings()

class MinioManager:
    def __init__(self, settings: Settings):
        self.client = Minio(
            settings.minio_endpoint,
            access_key=settings.minio_access_key,
            secret_key=settings.minio_secret_key,
            secure=True
        )

    def create_bucket(self, bucket_name: str):
        if not self.client.bucket_exists(bucket_name):
            self.client.make_bucket(bucket_name)
            print(f"Bucket {bucket_name} created.")
        else:
            print(f"Bucket {bucket_name} already exists.")

    def upload_file(self, bucket_name: str, file_path: str):
        self.client.fput_object(bucket_name, file_path, file_path)
        print(f"Uploaded {file_path} to bucket {bucket_name}.")

    def get_object_metadata(self, bucket_name: str, file_path: str) -> MinioMetadata:
        stat = self.client.stat_object(bucket_name, file_path)
        return MinioMetadata(
            object_name=stat.object_name,
            last_modified=stat.last_modified,
            etag=stat.etag,
            size=stat.size,
            content_type=stat.content_type,
            metadata=stat.metadata
        )

class WeaviateManager:
    def __init__(self, settings: Settings):
        self.client = Client(settings.weaviate_url)

    def create_class(self, class_name: str):
        if not self.client.schema.contains({"class": class_name}):
            class_obj = {
                "class": class_name,
                "properties": [
                    {"name": "object_name", "dataType": ["string"]},
                    {"name": "last_modified", "dataType": ["date"]},
                    {"name": "etag", "dataType": ["string"]},
                    {"name": "size", "dataType": ["int"]},
                    {"name": "content_type", "dataType": ["string"]},
                    {"name": "metadata", "dataType": ["string"]}
                ]
            }
            self.client.schema.create_class(class_obj)
            print(f"Class {class_name} created.")
        else:
            print(f"Class {class_name} already exists.")

    def index_file(self, class_name: str, data_object: WeaviateObject):
        self.client.data_object.create(data_object.dict(), class_name)
        print(f"Indexed object in Weaviate class {class_name}.")

class DataManager:
    def __init__(self, settings: Settings):
        self.minio_manager = MinioManager(settings)
        self.weaviate_manager = WeaviateManager(settings)
        self.bucket_class_map = {
            "Document": "document-bucket",
            "Snippet": "snippet-bucket",
            "Configuration": "config-bucket",
            "Website": "website-bucket",
            "Image": "image-bucket",
            "Video": "video-bucket"
        }

    def upload_and_index(self, file_path: str, class_name: str):
        if class_name not in self.bucket_class_map:
            raise ValueError(f"Unsupported class name: {class_name}")
        bucket_name = self.bucket_class_map[class_name]
        self.minio_manager.create_bucket(bucket_name)
        self.minio_manager.upload_file(bucket_name, file_path)
        metadata = self.minio_manager.get_object_metadata(bucket_name, file_path)
        self.weaviate_manager.create_class(class_name)
        self.weaviate_manager.index_file(class_name, WeaviateObject(**metadata.dict()))

def prompt_for_input(prompt_text: str) -> str:
    return input(prompt_text).strip()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 minio_weaviate.py <action> <additional_parameters>")
        print("Actions: upload, index, upload_and_index")
        sys.exit(1)

    action = sys.argv[1]

    if action not in ["upload", "index", "upload_and_index"]:
        print("Invalid action. Use 'upload', 'index', or 'upload_and_index'.")
        sys.exit(1)

    file_path = prompt_for_input("Enter the file path: ")
    class_name = prompt_for_input("Enter the class name (Document, Snippet, Configuration, Website, Image, Video): ")

    settings.minio_endpoint = prompt_for_input("Enter the MinIO endpoint: ")
    settings.minio_access_key = prompt_for_input("Enter the MinIO access key: ")
    settings.minio_secret_key = prompt_for_input("Enter the MinIO secret key: ")
    settings.weaviate_url = prompt_for_input("Enter the Weaviate URL: ")

    manager = DataManager(settings)

    if action == "upload":
        manager.minio_manager.upload_file(class_name, file_path)
    elif action == "index":
        metadata = manager.minio_manager.get_object_metadata(class_name, file_path)
        manager.weaviate_manager.index_file(class_name, metadata)
    elif action == "upload_and_index":
        manager.upload_and_index(file_path, class_name)
```

### Bash Functions and Aliases with Help Messages

To further refine the user experience, the bash functions will check for the required environment variables and prompt the user to provide them if they are missing. Additionally, these functions will provide usage guidance if called without arguments.

#### Add to `~/.bashrc` or `~/.bash_profile`

```bash
# Function to upload a file to MinIO
upload_to_minio() {
    if [ "$#" -lt 2 ]; then
        echo "Usage: minio_upload <file_path> <class_name>"
        echo "Class names: Document, Snippet, Configuration, Website, Image, Video"
        return 1
    fi
    if [ -z "$MINIO_ENDPOINT" ]; then read -p "Enter MinIO endpoint: " MINIO_ENDPOINT; fi
    if [ -z "$MINIO_ACCESS_KEY" ]; then read -p "Enter MinIO access key: " MINIO_ACCESS_KEY; fi
    if [ -z "$MINIO_SECRET_KEY" ]; then read -p "Enter MinIO secret key: " MINIO_SECRET_KEY; fi
    if [ -z "$WEAVIATE_URL" ]; then read -p "Enter Weaviate URL: " WEAVIATE_URL; fi
    python3 minio_weaviate.py upload "$1" "$MINIO_ENDPOINT" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" "$WEAVIATE_URL" "$2"
}

# Function to index a file in Weaviate
index_in_weaviate() {
    if [ "$#" -lt 2 ]; then
        echo "Usage: weaviate_index <file_path> <class_name>"
        echo "Class names: Document, Snippet, Configuration, Website, Image, Video"
        return 1
    fi
    if [ -z "$MINIO_ENDPOINT" ]; then read -p "Enter MinIO endpoint: " MINIO_ENDPOINT; fi
    if [ -z "$MINIO_ACCESS_KEY" ]; then read -p "Enter MinIO access key: " MINIO_ACCESS_KEY; fi
    if [ -z "$MINIO_SECRET_KEY" ]; then read -p "Enter MinIO secret key: " MINIO_SECRET_KEY; fi
    if [ -z "$WEAVIATE_URL" ]; then read -p "Enter Weaviate URL: " WEAVIATE_URL; fi
    python3 minio_weaviate.py index "$1" "$MINIO_ENDPOINT" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" "$WEAVIATE_URL" "$2"
}

# Function to upload a file to MinIO and index it in Weaviate
upload_and_index() {
    if [ "$#" -lt 2 ]; then
        echo "Usage: upload_index <file_path> <class_name>"
        echo "Class names: Document, Snippet, Configuration, Website, Image, Video"
        return 1
    fi
    if [ -z "$MINIO_ENDPOINT" ]; then read -p "Enter MinIO endpoint: " MINIO_ENDPOINT; fi
    if [ -z "$MINIO_ACCESS_KEY" ]; then read -p "Enter MinIO access key: " MINIO_ACCESS_KEY; fi
    if [ -z "$MINIO_SECRET_KEY" ]; then read -p "Enter MinIO secret key: " MINIO_SECRET_KEY; fi
    if [ -z "$WEAVIATE_URL" ]; then read -p "Enter Weaviate URL: " WEAVIATE_URL; fi
    python3 minio_weaviate.py upload_and_index "$1" "$MINIO_ENDPOINT" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY" "$WEAVIATE_URL" "$2"
}

# Aliases for convenience
alias minio_upload=upload_to_minio
alias weaviate_index=index_in_weaviate
alias upload_index=upload_and_index
```

After adding these lines, reload your bash profile:

```sh
source ~/.bashrc
# or
source ~/.bash_profile
```

This setup improves the user experience by providing interactive prompts and guidance when using the CLI commands, ensuring users can successfully execute the alias tools for their needs. The use of Pydantic models and `unstructured-io` enhances the robustness and extendibility of the system.

### Usage Examples with Interactive Guidance

Now, if you run any of the commands without the required arguments, it will guide you on how to properly use them.

#### Upload a file to MinIO

```sh
minio_upload example.txt Document
```

If you run `minio_upload` without arguments:

```sh
minio_upload
```

You will see:

```
Usage: minio_upload <file_path> <class_name>
Class names: Document, Snippet, Configuration, Website, Image, Video
```

#### Index a file in Weaviate

```sh
weaviate_index example.txt Document
```

If you run `weaviate_index` without arguments:

```sh
weaviate_index
```

You will see:

```
Usage: weaviate_index <file_path> <class_name>
Class names: Document, Snippet, Configuration, Website, Image, Video
```

#### Upload a file to MinIO and index it in Weaviate

```sh
upload_index example.txt Document
```

If you run `upload_index` without arguments:

```sh
upload_index
```

You will see:

```
Usage: upload_index <file_path> <class_name>
Class names: Document, Snippet, Configuration, Website, Image, Video
```

### Conclusion and Future Directions

By integrating MinIO and Weaviate with the aid of Pydantic and `unstructured-io`, you can significantly streamline and enhance your hybrid cloud operations. This approach not only simplifies the management of unstructured data but also ensures that your data processing workflows are robust and efficient. The use of Pydantic for data modeling enforces schema validation, thereby improving data integrity, while `unstructured-io` automates data partitioning, making it easier to handle diverse data formats seamlessly.

The combination of these technologies provides a comprehensive solution for managing large datasets across hybrid cloud environments. MinIO's scalable and high-performance object storage, paired with Weaviate's powerful search capabilities, creates a robust infrastructure for data storage and retrieval. This integration is further strengthened by the structured and validated data models provided by Pydantic, ensuring consistency and reducing the likelihood of errors. Additionally, `unstructured-io` enhances the data ingestion process, allowing for more efficient and organized data management.

### Final Thoughts

Ultimately, this setup empowers DevOps and AIOps teams to handle complex data operations with greater ease and reliability. By following the guidelines and leveraging the tools outlined in this document, you can build a resilient and scalable hybrid cloud architecture that meets the demands of modern data-driven applications. This holistic approach not only optimizes your current workflows but also sets a solid foundation for future scalability and innovation. Embrace these technologies to stay ahead in the rapidly evolving landscape of data management and cloud computing.
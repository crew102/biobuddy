## Python: Secrets Manager (`inst/python/secrets.py`)

Single helper to retrieve a secret value by name from AWS Secrets Manager.

- **`get_secret(secret_name)`** → returns the value corresponding to `secret_name` from the secret's JSON map.

Example:

```python
from inst.python.secrets import get_secret

api_key = get_secret("OPENAI_API_KEY")
```


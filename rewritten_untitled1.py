class LlmAgent:
    def __init__(self, name: str):
        self.name = name

# 2. Base Agent Classes
class DataForager(LlmAgent):
    def __init__(self):
        super().__init__(
            name="data_forager"
        )

class LlmAgent:
    """Base class for LLM-powered agents"""
    def __init__(self, name: str, **kwargs):
        self.name = name
        # Add any common LLM agent initialization here

    def __call__(self, *args, **kwargs):
        """Base call method that should be implemented by subclasses"""
        raise NotImplementedError("Subclasses must implement __call__")


class DataForager(LlmAgent):
    """Agent specialized in data collection and processing"""
    def __init__(self):
        super().__init__(
            name="data_forager",
            # Add any DataForager specific initialization here
        )

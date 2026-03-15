class SafetyGate:
    HIGH_RISK_KEYWORDS = [
        "payment", "pay", "purchase", "buy",
        "delete", "remove", "unsubscribe",
        "submit", "confirm order",
        "login", "sign in", "password",
        "transfer", "send money",
    ]

    MEDIUM_RISK_KEYWORDS = [
        "change settings", "modify settings",
        "account settings", "reset",
        "toggle", "enable", "disable",
        "turn off", "turn on",
        "factory reset", "clear data",
    ]

    def classify_risk(self, action_text: str) -> str:
        text_lower = action_text.lower()
        for kw in self.HIGH_RISK_KEYWORDS:
            if kw in text_lower:
                return "high"
        for kw in self.MEDIUM_RISK_KEYWORDS:
            if kw in text_lower:
                return "medium"
        return "low"

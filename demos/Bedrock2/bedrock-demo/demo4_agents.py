"""Demo 4: Bedrock Agents — Tool Use via the Converse API.

Shows the model reasoning about WHEN to call tools and using the results.
Uses the Converse API's native toolUse capability for a clean, instant demo.

Talking point: In production, Bedrock Agents wraps this into a fully managed
service with action groups, Lambda integration, and multi-step orchestration.
"""
import json
import random
from config import bedrock_runtime, get_smart_model, print_header, print_step

MODEL_ID = get_smart_model()

# Define tools the model can use
TOOLS = [
    {
        "toolSpec": {
            "name": "get_weather",
            "description": "Get the current weather for a city. Returns temperature, conditions, and humidity.",
            "inputSchema": {
                "json": {
                    "type": "object",
                    "properties": {
                        "city": {
                            "type": "string",
                            "description": "The city name, e.g. 'Seattle' or 'New York'",
                        }
                    },
                    "required": ["city"],
                }
            },
        }
    },
    {
        "toolSpec": {
            "name": "get_time",
            "description": "Get the current local time for a city.",
            "inputSchema": {
                "json": {
                    "type": "object",
                    "properties": {
                        "city": {
                            "type": "string",
                            "description": "The city name",
                        }
                    },
                    "required": ["city"],
                }
            },
        }
    },
]

# Simulated tool implementations
WEATHER_DATA = {
    "seattle": {"temp": 58, "conditions": "Overcast", "humidity": 78},
    "new york": {"temp": 72, "conditions": "Partly cloudy", "humidity": 55},
    "miami": {"temp": 88, "conditions": "Sunny", "humidity": 70},
    "london": {"temp": 62, "conditions": "Rainy", "humidity": 85},
}

TIME_DATA = {
    "seattle": "2:35 PM PST",
    "new york": "5:35 PM EST",
    "miami": "5:35 PM EST",
    "london": "10:35 PM GMT",
}


def execute_tool(name: str, input_data: dict) -> str:
    """Simulate executing a tool and returning results."""
    city = input_data.get("city", "").lower()
    if name == "get_weather":
        data = WEATHER_DATA.get(city, {"temp": 65, "conditions": "Clear", "humidity": 50})
        return json.dumps({"city": city.title(), "temperature_f": data["temp"],
                          "conditions": data["conditions"], "humidity_pct": data["humidity"]})
    elif name == "get_time":
        time_str = TIME_DATA.get(city, "12:00 PM UTC")
        return json.dumps({"city": city.title(), "local_time": time_str})
    return json.dumps({"error": "Unknown tool"})


def converse_with_tools(prompt: str):
    """Run a full tool-use conversation loop."""
    messages = [{"role": "user", "content": [{"text": prompt}]}]

    print(f"  User: {prompt}")

    # Step 1: Send message with tool definitions
    resp = bedrock_runtime().converse(
        modelId=MODEL_ID,
        messages=messages,
        toolConfig={"tools": TOOLS},
        inferenceConfig={"maxTokens": 1024, "temperature": 0},
    )

    # Conversation loop — handle tool calls
    while resp["stopReason"] == "tool_use":
        assistant_msg = resp["output"]["message"]
        messages.append(assistant_msg)

        tool_results = []
        for block in assistant_msg["content"]:
            if "toolUse" in block:
                tool = block["toolUse"]
                print(f"  🔧 Model calls tool: {tool['name']}({json.dumps(tool['input'])})")
                result = execute_tool(tool["name"], tool["input"])
                print(f"  📦 Tool result: {result}")
                tool_results.append({
                    "toolResult": {
                        "toolUseId": tool["toolUseId"],
                        "content": [{"json": json.loads(result)}],
                    }
                })

        # Step 2: Send tool results back to the model
        messages.append({"role": "user", "content": tool_results})
        resp = bedrock_runtime().converse(
            modelId=MODEL_ID,
            messages=messages,
            toolConfig={"tools": TOOLS},
            inferenceConfig={"maxTokens": 1024, "temperature": 0},
        )

    # Final response
    final_text = resp["output"]["message"]["content"][0]["text"]
    print(f"  🤖 Agent: {final_text}")
    return final_text


def main():
    print_header("Demo 4: Bedrock Agents — Tool Use")

    print("The model decides WHEN to call tools based on the user's question.\n")
    print("Available tools: get_weather, get_time\n")

    # Test 1: Requires a tool call
    print_step("Query 1: Requires weather tool")
    converse_with_tools("What's the weather like in Seattle right now?")

    # Test 2: Requires multiple tool calls
    print_step("Query 2: Requires MULTIPLE tool calls")
    converse_with_tools("Compare the weather in Miami and London. Which is warmer?")

    # Test 3: No tool needed — model answers directly
    print_step("Query 3: No tool needed (model answers from knowledge)")
    converse_with_tools("What is the capital of Japan?")

    print("\n✅ Key takeaway: The model REASONS about when to use tools, calls them,")
    print("   and synthesizes results. In production, Bedrock Agents adds managed")
    print("   orchestration, Lambda action groups, and multi-step planning.\n")


if __name__ == "__main__":
    main()

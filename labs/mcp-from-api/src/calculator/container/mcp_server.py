import math
import uvicorn

# Support either the standalone 'fastmcp' package or the 'mcp' package layout.
try:
    from fastmcp import FastMCP, Context  # pip install fastmcp
except ModuleNotFoundError:  # fall back to the layout you used originally
    from mcp.server.fastmcp import FastMCP, Context  # pip install mcp

from starlette.applications import Starlette
from starlette.routing import Mount


mcp = FastMCP("Calculator")


@mcp.tool()
async def calculate(ctx: Context, operation: str, a: float, b: float) -> str:
    """Perform a math operation. Supported operations: add, subtract, multiply, divide, power, modulo."""
    ops = {
        "add": lambda x, y: x + y,
        "subtract": lambda x, y: x - y,
        "multiply": lambda x, y: x * y,
        "divide": lambda x, y: x / y if y != 0 else "Error: Division by zero",
        "power": lambda x, y: x ** y,
        "modulo": lambda x, y: x % y if y != 0 else "Error: Division by zero",
    }
    op = operation.lower()
    if op not in ops:
        return f"Error: Unknown operation '{operation}'. Supported: {list(ops.keys())}"
    result = ops[op](a, b)
    return str({"operation": op, "a": a, "b": b, "result": result})


@mcp.tool()
async def sqrt(ctx: Context, value: float) -> str:
    """Calculate the square root of a number."""
    if value < 0:
        return "Error: Cannot calculate square root of a negative number"
    return str({"value": value, "result": round(math.sqrt(value), 10)})


@mcp.tool()
async def convert_units(ctx: Context, value: float, from_unit: str, to_unit: str) -> str:
    """Convert between common units. Supported: km/miles, kg/lbs, celsius/fahrenheit, liters/gallons."""
    conversions = {
        ("km", "miles"): lambda v: v * 0.621371,
        ("miles", "km"): lambda v: v * 1.60934,
        ("kg", "lbs"): lambda v: v * 2.20462,
        ("lbs", "kg"): lambda v: v * 0.453592,
        ("celsius", "fahrenheit"): lambda v: v * 9 / 5 + 32,
        ("fahrenheit", "celsius"): lambda v: (v - 32) * 5 / 9,
        ("liters", "gallons"): lambda v: v * 0.264172,
        ("gallons", "liters"): lambda v: v * 3.78541,
    }
    key = (from_unit.lower(), to_unit.lower())
    if key not in conversions:
        supported = [f"{f}→{t}" for f, t in conversions.keys()]
        return f"Error: Unsupported conversion '{from_unit}' → '{to_unit}'. Supported: {supported}"
    result = round(conversions[key](value), 6)
    return str({"value": value, "from": from_unit, "to": to_unit, "result": result})


# Expose an ASGI app that speaks Streamable HTTP at /calculator/
mcp_asgi = mcp.http_app()
app = Starlette(
    routes=[Mount("/calculator", app=mcp_asgi)],
    lifespan=mcp_asgi.lifespan,
)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Run MCP Streamable-HTTP server")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8080, help="Port to listen on")
    args = parser.parse_args()
    uvicorn.run(app, host=args.host, port=args.port)

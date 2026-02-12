import uuid
from datetime import datetime, timezone
import uvicorn

# Support either the standalone 'fastmcp' package or the 'mcp' package layout.
try:
    from fastmcp import FastMCP, Context  # pip install fastmcp
except ModuleNotFoundError:
    from mcp.server.fastmcp import FastMCP, Context  # pip install mcp

from starlette.applications import Starlette
from starlette.routing import Mount


# In-memory orders store
ORDERS: list[dict] = []

# Available products (simplified catalog for validation)
VALID_PRODUCTS = {
    "PROD-001": {"name": "Wireless Mouse", "price": 29.99},
    "PROD-002": {"name": "Mechanical Keyboard", "price": 89.99},
    "PROD-003": {"name": "USB-C Hub", "price": 49.99},
    "PROD-004": {"name": "Standing Desk Mat", "price": 39.99},
    "PROD-005": {"name": "Monitor Arm", "price": 119.99},
    "PROD-006": {"name": "Laptop Backpack", "price": 59.99},
    "PROD-007": {"name": "Webcam HD", "price": 69.99},
    "PROD-008": {"name": "Desk Organizer", "price": 24.99},
}

mcp = FastMCP("OrderService")

@mcp.tool()
async def place_order(ctx: Context, product_id: str, quantity: int) -> str:
    """Place an order for a product. Requires a valid product ID and quantity (1-100)."""
    product_id = product_id.upper()
    if product_id not in VALID_PRODUCTS:
        return f"Error: Product '{product_id}' not found. Valid IDs: {list(VALID_PRODUCTS.keys())}"
    if quantity < 1 or quantity > 100:
        return "Error: Quantity must be between 1 and 100"

    product = VALID_PRODUCTS[product_id]
    order = {
        "order_id": f"ORD-{uuid.uuid4().hex[:8].upper()}",
        "product_id": product_id,
        "product_name": product["name"],
        "quantity": quantity,
        "unit_price": product["price"],
        "total": round(product["price"] * quantity, 2),
        "status": "confirmed",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    ORDERS.append(order)
    return str(order)

@mcp.tool()
async def get_order(ctx: Context, order_id: str) -> str:
    """Get details of a specific order by its order ID (e.g. ORD-A1B2C3D4)."""
    order_id = order_id.upper()
    for order in ORDERS:
        if order["order_id"] == order_id:
            return str(order)
    return f"Order '{order_id}' not found"

@mcp.tool()
async def list_orders(ctx: Context) -> str:
    """List all orders placed in the current session."""
    if not ORDERS:
        return "No orders placed yet"
    return str(ORDERS)


# Expose an ASGI app that speaks Streamable HTTP at /order/
mcp_asgi = mcp.http_app()
app = Starlette(
    routes=[Mount("/order", app=mcp_asgi)],
    lifespan=mcp_asgi.lifespan,
)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Run MCP Streamable-HTTP server")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8080, help="Port to listen on")
    args = parser.parse_args()
    uvicorn.run(app, host=args.host, port=args.port)

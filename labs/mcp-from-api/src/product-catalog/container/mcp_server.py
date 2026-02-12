import uvicorn

# Support either the standalone 'fastmcp' package or the 'mcp' package layout.
try:
    from fastmcp import FastMCP, Context  # pip install fastmcp
except ModuleNotFoundError:
    from mcp.server.fastmcp import FastMCP, Context  # pip install mcp

from starlette.applications import Starlette
from starlette.routing import Mount


# In-memory product catalog
PRODUCTS = [
    {"id": "PROD-001", "name": "Wireless Mouse", "category": "Electronics", "price": 29.99, "stock": 150, "description": "Ergonomic wireless mouse with 2.4GHz connectivity"},
    {"id": "PROD-002", "name": "Mechanical Keyboard", "category": "Electronics", "price": 89.99, "stock": 75, "description": "RGB mechanical keyboard with Cherry MX switches"},
    {"id": "PROD-003", "name": "USB-C Hub", "category": "Electronics", "price": 49.99, "stock": 200, "description": "7-in-1 USB-C hub with HDMI, USB-A, and SD card reader"},
    {"id": "PROD-004", "name": "Standing Desk Mat", "category": "Office", "price": 39.99, "stock": 120, "description": "Anti-fatigue standing desk mat with beveled edges"},
    {"id": "PROD-005", "name": "Monitor Arm", "category": "Office", "price": 119.99, "stock": 60, "description": "Adjustable single monitor arm for screens up to 32 inches"},
    {"id": "PROD-006", "name": "Laptop Backpack", "category": "Accessories", "price": 59.99, "stock": 300, "description": "Water-resistant laptop backpack with USB charging port"},
    {"id": "PROD-007", "name": "Webcam HD", "category": "Electronics", "price": 69.99, "stock": 90, "description": "1080p HD webcam with built-in microphone and privacy cover"},
    {"id": "PROD-008", "name": "Desk Organizer", "category": "Office", "price": 24.99, "stock": 250, "description": "Bamboo desk organizer with pen holder and phone stand"},
]

mcp = FastMCP("ProductCatalog")

@mcp.tool()
async def search_products(ctx: Context, query: str) -> str:
    """Search products by name, category, or description. Returns matching products from the catalog."""
    query_lower = query.lower()
    results = [
        p for p in PRODUCTS
        if query_lower in p["name"].lower()
        or query_lower in p["category"].lower()
        or query_lower in p["description"].lower()
    ]
    if not results:
        return f"No products found matching '{query}'"
    return str(results)

@mcp.tool()
async def get_product(ctx: Context, product_id: str) -> str:
    """Get detailed information about a specific product by its ID (e.g. PROD-001)."""
    for p in PRODUCTS:
        if p["id"].upper() == product_id.upper():
            return str(p)
    return f"Product '{product_id}' not found"

@mcp.tool()
async def list_categories(ctx: Context) -> str:
    """List all available product categories with product counts."""
    categories = {}
    for p in PRODUCTS:
        cat = p["category"]
        categories[cat] = categories.get(cat, 0) + 1
    return str(categories)

@mcp.tool()
async def check_stock(ctx: Context, product_id: str) -> str:
    """Check the stock availability for a specific product by its ID."""
    for p in PRODUCTS:
        if p["id"].upper() == product_id.upper():
            status = "In Stock" if p["stock"] > 0 else "Out of Stock"
            return str({"product_id": p["id"], "name": p["name"], "stock": p["stock"], "status": status})
    return f"Product '{product_id}' not found"


# Expose an ASGI app that speaks Streamable HTTP at /catalog/
mcp_asgi = mcp.http_app()
app = Starlette(
    routes=[Mount("/catalog", app=mcp_asgi)],
    lifespan=mcp_asgi.lifespan,
)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Run MCP Streamable-HTTP server")
    parser.add_argument("--host", default="0.0.0.0", help="Host to bind to")
    parser.add_argument("--port", type=int, default=8080, help="Port to listen on")
    args = parser.parse_args()
    uvicorn.run(app, host=args.host, port=args.port)

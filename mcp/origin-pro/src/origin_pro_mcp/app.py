"""Origin Pro MCP Server — application entry point.

Upstream 0.2.0 imports ``mcp.server.fastmcp.FastMCP``. The MCP Python SDK 2.x
renamed that module to ``mcp.server.mcpserver`` and the class to ``MCPServer``.
The two APIs used here (``tool()`` decorator and ``run(transport="stdio")``)
are identical, so pick whichever import exists and keep the module-level name
``mcp`` that every tool module imports.
"""

try:  # MCP Python SDK 1.x
    from mcp.server.fastmcp import FastMCP as _MCPServer
except ModuleNotFoundError:  # MCP Python SDK 2.x
    from mcp.server.mcpserver import MCPServer as _MCPServer

mcp = _MCPServer("origin-pro")


def main():
    """Entry point for uvx / console_scripts."""
    from . import server  # noqa: F401 — registers all tools
    mcp.run(transport="stdio")

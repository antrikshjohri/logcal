"use client";

export default function GlobalError() {
  return (
    <html lang="en">
      <body>
        <main
          style={{
            minHeight: "100vh",
            display: "grid",
            placeItems: "center",
            padding: "24px",
            fontFamily: "Manrope, sans-serif",
            background: "#fffdf8",
            color: "#061b17"
          }}
        >
          <div style={{ textAlign: "center" }}>
            <h1 style={{ margin: 0, fontSize: "32px" }}>Something went wrong</h1>
            <p style={{ marginTop: "12px", fontSize: "18px", color: "#5d6663" }}>
              Refresh the page and try again.
            </p>
          </div>
        </main>
      </body>
    </html>
  );
}

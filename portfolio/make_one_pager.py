"""Build the one-page English portfolio sheet from verified project outputs.

Run from any folder with: python portfolio/make_one_pager.py
Requires reportlab; runProject must first generate the figure in results/.
"""
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase.pdfmetrics import stringWidth
from reportlab.pdfgen import canvas

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = Path(__file__).with_name("longitudinal_flight_dynamics_one_pager.pdf")
FIGURE = ROOT / "results" / "wing_lift_static_difference.png"
REPO = "https://github.com/nclblnv44/cfd-informed-longitudinal-flight-dynamics"
NASA = "https://tmbwg.github.io/turbmodels/naca0012_val.html"

NAVY = colors.HexColor("#13263B")
TEAL = colors.HexColor("#087E8B")
PALE = colors.HexColor("#EAF4F5")
INK = colors.HexColor("#243444")
MUTED = colors.HexColor("#526477")


def text(c, x, y, value, size=10, font="Helvetica", color=INK):
    c.setFillColor(color)
    c.setFont(font, size)
    c.drawString(x, y, value)


def lines(c, x, y, values, size=9.2, leading=13, color=INK):
    for value in values:
        text(c, x, y, value, size=size, color=color)
        y -= leading
    return y


def card(c, x, y, width, label, headline, detail):
    c.setFillColor(PALE)
    c.roundRect(x, y, width, 78, 8, fill=1, stroke=0)
    text(c, x + 11, y + 58, label.upper(), 8, "Helvetica-Bold", TEAL)
    text(c, x + 11, y + 34, headline, 14.5, "Helvetica-Bold", NAVY)
    text(c, x + 11, y + 16, detail, 8.1, "Helvetica", MUTED)


def make_pdf():
    if not FIGURE.exists():
        raise FileNotFoundError(f"Run runProject first; missing {FIGURE}")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    c = canvas.Canvas(str(OUTPUT), pagesize=A4)
    w, h = A4
    margin = 42

    c.setFillColor(NAVY)
    c.rect(0, h - 118, w, 118, fill=1, stroke=0)
    text(c, margin, h - 46, "CFD-informed longitudinal", 20, "Helvetica-Bold", colors.white)
    text(c, margin, h - 70, "flight dynamics simulator", 20, "Helvetica-Bold", colors.white)
    text(c, margin, h - 94, "Nicola Blinov  |  MATLAB + ANSYS Fluent  |  Academic project", 10, color=colors.HexColor("#C8E7EA"))

    text(c, margin, 703, "THE QUESTION", 9, "Helvetica-Bold", TEAL)
    lines(c, margin, 686, [
        "How does a measured-range CFD airfoil polar change the longitudinal response",
        "of a conceptual aircraft compared with a local linear lift law?"
    ], size=10, leading=14)

    text(c, margin, 642, "METHOD", 9, "Helvetica-Bold", TEAL)
    lines(c, margin, 625, [
        "NACA 0012 Fluent polar (Re 6e6, Mach 0.15, 449x129 mesh, -4 to 12 deg)",
        "-> finite-wing correction -> separate trims -> 20 s ode45 elevator-pulse runs."
    ], size=9.5, leading=14)

    text(c, margin, 585, "STATIC LIFT DIFFERENCE ACROSS THE AVAILABLE POLAR", 9, "Helvetica-Bold", TEAL)
    c.drawImage(ImageReader(str(FIGURE)), margin, 319, width=w - 2 * margin, height=254, preserveAspectRatio=True, anchor="c", mask="auto")

    card(c, margin, 221, 160, "Trim, 52 m/s", "3.573 / 3.570 deg", "alpha: linear / CFD lift")
    card(c, margin + 171, 221, 160, "Pulse peak", "0.3467 / 0.3469 deg", "|Delta alpha|: linear / CFD")
    card(c, margin + 342, 221, 169, "Pitch-rate peak", "1.639 / 2.408 deg/s", "kq = 1 / kq = 0")

    text(c, margin, 197, "RESULT AND LIMITS", 9, "Helvetica-Bold", TEAL)
    lines(c, margin, 181, [
        "Near their trims, the two lift laws are nearly linear and the same -0.5 deg",
        "elevator pulse gives alpha-deviation curves within 0.000222 deg (maximum).",
        "Experimental comparison validates the airfoil polar only (CL RMSE 0.011526);",
        "the conceptual aircraft dynamics are not experimentally validated."
    ], size=9.1, leading=13)

    text(c, margin, 116, "CONTRIBUTION", 9, "Helvetica-Bold", TEAL)
    lines(c, margin, 101, [
        "Nicola: Fluent CFD campaign, physical model setup, and part of the MATLAB code.",
        "MATLAB implementation and documentation also developed with Codex assistance."
    ], size=8.4, leading=12)

    c.setStrokeColor(colors.HexColor("#B9C8D2"))
    c.line(margin, 67, w - margin, 67)
    text(c, margin, 54, "Code, results and reproduction:", 8.2, "Helvetica-Bold", NAVY)
    text(c, margin, 42, REPO, 8.0, color=TEAL)
    c.linkURL(REPO, (margin, 39, w - margin, 57), relative=0)
    text(c, margin, 25, "Experimental airfoil source: NASA Turbulence Modeling Resource (Ladson).", 7.7, color=MUTED)
    c.linkURL(NASA, (margin, 23, w - margin, 36), relative=0)

    c.showPage()
    c.save()
    print(OUTPUT)


if __name__ == "__main__":
    make_pdf()

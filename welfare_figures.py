"""
Welfare effects of animal-welfare disclosure (Section 5.4).

    dW_pk = N_pk * y_pk^phi * (WTK+_pk * WTP_pk - WTK-_pk * WTPn_pk)        Eq. (7)

    N_pk    adult population_k * share of adults who buy p and are not yet informed
    WTK+    P(want info | decider), WTK- = 1 - WTK+
    WTP     mean valuation in euros among those who want the information
    WTPn    mean valuation in euros among those who avoid it
    y_pk    purchase frequency per buyer per year
    phi     frequency-scaling exponent (0: valued once per year, 1: at every purchase)

Run analysis.do first; it writes the inputs to output/welfare/.
Figures and tables are written to output/welfare/out/.
"""

from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.colors import TwoSlopeNorm, LinearSegmentedColormap
from matplotlib.patches import Patch

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "output" / "welfare"
OUT = DATA / "out"
OUT.mkdir(exist_ok=True)

FREQ_FILE = ROOT / "data" / "buying_frequencies.xlsx"

# Adult (18+) population (accessed 15 July 2026)
#   US           Annie E. Casey Foundation, KIDS COUNT Data Center (U.S. Census Bureau estimates)
#                https://datacenter.aecf.org/data/tables/99-total-population-by-child-and-adult-populations
#   Germany      Destatis, current population
#                https://www.destatis.de/EN/Themes/Society-Environment/Population/Current-Population/_node.html
#   Denmark      Danmarks Statistik
#                https://www.dst.dk/en/Statistik/emner/borgere/befolkning/befolkningstal
#   UK           ONS, UK population estimates
#                https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/timeseries/ukpop/pop
#   France       https://statbase.org/data/fra-population-age-18-and-above/
#   Netherlands  https://statbase.org/data/nld-population-age-18-and-above/
ADULT_POP = {
    "Denmark":      4_700_000,
    "France":      53_000_000,
    "Germany":     70_000_000,
    "Netherlands": 15_000_000,
    "UK":          54_000_000,
    "US":         270_000_000,
}

PHI_MAIN = 0.5
PHI_REPORT = [0.0, 0.5, 1.0]
PHI_GRID = np.linspace(0, 1, 41)

# Fur is not reported: 15-62 deciders and 4-17 avoiders per country.
DROP_PRODUCTS = ["fur"]

# The trade-data frequency for leather (0.06-0.27 per year) covers leather apparel only
# (HS 420310), while the survey asked about any leather item. One purchase per year is assumed.
FREQ_OVERRIDE = {"leather": 1.0}

PRODUCT_ORDER = ["meat", "egg", "milk", "leather", "cosmetic", "pfood", "otc"]
PRODUCT_LABEL = {
    "meat": "Meat", "egg": "Eggs", "milk": "Milk", "fur": "Fur",
    "leather": "Leather", "cosmetic": "Cosmetics", "pfood": "Pet food", "otc": "OTC",
}
ALL_PRODUCTS = PRODUCT_ORDER + DROP_PRODUCTS
COUNTRY_ORDER = ["Denmark", "France", "Germany", "Netherlands", "UK", "US"]

# product names in the frequency workbook -> product codes in the Stata output
FREQ_PRODUCT_MAP = {
    "meat": "meat", "eggs": "egg", "milk": "milk", "cosmetics": "cosmetic",
    "pet food": "pfood", "medication": "otc", "fur": "fur", "leather": "leather",
}

NAVY, MAROON, GREY = "#1A476F", "#90353B", "#7F7F7F"

plt.rcParams.update({
    "font.family": "serif",
    "font.serif": ["Times New Roman", "STIXGeneral", "DejaVu Serif"],
    "mathtext.fontset": "stix",
    "font.size": 11,
    "axes.spines.top": False,
    "axes.spines.right": False,
})


# ---------------------------------------------------------------------------
# Loaders
# ---------------------------------------------------------------------------

def load_welfare_inputs(path=DATA / "welfare_inputs_country_category.csv"):
    """Country x category inputs."""
    d = pd.read_csv(path)

    # strip the Stata value-label prefix: "[1] Denmark" -> "Denmark"
    d["country"] = (d["country"].astype(str)
                    .str.replace(r"^\[\d+\]\s*", "", regex=True)
                    .replace({"USA": "US"}))

    assert np.allclose(d.pi_plus + d.pi_minus, 1, atol=1e-6), "pi_plus + pi_minus != 1"

    d["adult_pop"] = d["country"].map(ADULT_POP)
    assert d["adult_pop"].notna().all(), "unmapped country in ADULT_POP"

    d["N"] = d["adult_pop"] * d["decider_share_pop"]
    return d


def for_figures(x):
    """Drop the categories that are not reported (fur)."""
    return x[~x["product"].isin(DROP_PRODUCTS)].copy()


def load_frequencies(path=FREQ_FILE):
    """Purchase frequency per buyer per year."""
    xl = pd.ExcelFile(path)

    def read_block(sheet):
        raw = pd.read_excel(xl, sheet, header=None)
        hdr = next(i for i in range(25) if str(raw.iloc[i, 0]).strip() == "Product")
        b = pd.read_excel(xl, sheet, header=hdr)
        b = b.dropna(subset=["Product", "Frequency per buyer / yr"])
        b = b[b["Country"].isin(COUNTRY_ORDER)]
        return b[["Product", "Country", "Frequency per buyer / yr"]]

    f = pd.concat([read_block("Frequency (per buyer)"),
                   read_block("Fur & Leather (trade data)")], ignore_index=True)
    f.columns = ["product", "country", "freq"]
    f["product"] = f["product"].str.strip().map(FREQ_PRODUCT_MAP)
    assert f["product"].notna().all(), "unmapped product in FREQ_PRODUCT_MAP"
    assert len(f) == 48, f"expected 48 country x product frequencies, got {len(f)}"

    for p, y in FREQ_OVERRIDE.items():
        f.loc[f["product"] == p, "freq"] = y

    # y^phi lies between 1 (a single occasion) and y (every occasion) only if y >= 1
    bad = f[(f["freq"] < 1) & (~f["product"].isin(DROP_PRODUCTS))]
    assert bad.empty, f"frequency < 1 for reported categories:\n{bad}"
    return f


def load_value_grid(path=DATA / "predictions_values_all.csv"):
    """Predicted WTK, WTP (%) and WTPn (%) over the 7x7x7 grid of value components."""
    g = pd.read_csv(path)
    assert len(g) == 343, f"expected 343 grid points, got {len(g)}"
    return g


# ---------------------------------------------------------------------------
# Welfare effect, Eq. (7)
# ---------------------------------------------------------------------------

def welfare_cells(d, freq, phi):
    """Eq. (7) per country x category, in euros."""
    m = d.merge(freq, on=["country", "product"], how="left", validate="1:1")
    assert m["freq"].notna().all(), "missing frequency for some cell"

    scale = m["freq"] ** phi if phi > 0 else 1.0
    m["benefit"] = m["N"] * scale * m["pi_plus"] * m["mu_plus"]
    m["loss"] = m["N"] * scale * m["pi_minus"] * m["mu_minus"]
    m["net"] = m["benefit"] - m["loss"]
    return m


def aggregate(cells, by):
    """Sum net welfare over the given dimension (reported categories only)."""
    return for_figures(cells).groupby(by)["net"].sum()


d = load_welfare_inputs()
freq = load_frequencies()
cells = welfare_cells(d, freq, PHI_MAIN)

print(f"phi = {PHI_MAIN}   cells = {len(cells)}   adult pop = {sum(ADULT_POP.values())/1e6:.1f}m")
print(for_figures(cells).groupby("product")["net"].sum().div(1e9).round(2))


# ---------------------------------------------------------------------------
# Net welfare by category
# ---------------------------------------------------------------------------

def fig1_by_category(cells):
    """Seven reported categories and their sum."""
    c = for_figures(cells)
    by_p = c.groupby("product")["net"].sum() / 1e9
    vals = [by_p[p] for p in PRODUCT_ORDER]
    overall = sum(vals)

    labels = [PRODUCT_LABEL[p] for p in PRODUCT_ORDER] + ["Overall"]
    heights = vals + [overall]
    x = np.arange(len(heights))

    fig, ax = plt.subplots(figsize=(8.6, 4.6))
    for xi, h, p in zip(x, heights, PRODUCT_ORDER + ["overall"]):
        ax.bar(xi, h, color=MAROON if p == "overall" else NAVY, edgecolor="none")
        ax.text(xi, h + max(heights) * 0.015, f"{h:.2f}", ha="center", fontsize=8.5)

    ax.axhline(0, color="black", lw=0.8)
    ax.set_xticks(x)
    ax.set_xticklabels(labels, fontsize=9.5)
    ax.set_ylabel("Net welfare effect (billion euros)")
    ax.set_ylim(0, max(heights) * 1.15)
    ax.legend(handles=[Patch(facecolor=NAVY, label="Product category"),
                       Patch(facecolor=MAROON, label="Overall (sum)")],
              loc="upper left", frameon=False, fontsize=8.5)

    fig.tight_layout()
    fig.savefig(OUT / "fig1_welfare_by_category.png", dpi=300, bbox_inches="tight")
    return by_p, overall


by_p, overall = fig1_by_category(cells)
print(f"OVERALL: {overall:.2f} bn EUR")


# ---------------------------------------------------------------------------
# Net welfare by country
# ---------------------------------------------------------------------------

def fig2_by_country(cells):
    """Net welfare per country, summed over the reported categories."""
    by_k = aggregate(cells, "country") / 1e9
    vals = [by_k[k] for k in COUNTRY_ORDER]
    x = np.arange(len(COUNTRY_ORDER))

    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    ax.bar(x, vals, color=NAVY, edgecolor="none")
    for xi, h in zip(x, vals):
        ax.text(xi, h + max(vals) * 0.015, f"{h:.1f}", ha="center", fontsize=9)
    ax.axhline(0, color="black", lw=0.8)
    ax.set_xticks(x)
    ax.set_xticklabels(COUNTRY_ORDER)
    ax.set_ylabel("Net welfare effect (billion euros)")
    ax.set_ylim(0, max(vals) * 1.15)

    fig.tight_layout()
    fig.savefig(OUT / "fig2_welfare_by_country.png", dpi=300, bbox_inches="tight")
    return by_k


by_k = fig2_by_country(cells)
print(by_k[COUNTRY_ORDER].round(3))


# ---------------------------------------------------------------------------
# Welfare surface over the value components
# ---------------------------------------------------------------------------

CMAP = LinearSegmentedColormap.from_list("mwn", [MAROON, "#FFFFFF", NAVY])


def contour_scaling(cells, phi=PHI_MAIN):
    """K = sum over k,p of N_pk * y_pk^phi * price_pk."""
    c = for_figures(cells)
    scale = c["freq"] ** phi if phi > 0 else 1.0
    return (c["N"] * scale * c["price_mean"]).sum()


def contour_surface(grid, K):
    """Net welfare over the aff x inst x cogn grid, in billion euros.

    The index models predict WTP and WTPn as percentages of the price, so the
    conversion to euros and the population scaling reduce to the constant K.
    """
    T = np.zeros((7, 7, 7))
    for _, r in grid.iterrows():
        a, i, c = int(r.aff) - 1, int(r.inst) - 1, int(r.cogn) - 1
        wtk = r.pred_wtk
        T[a, c, i] = K * (wtk * r.pred_wtp / 100 - (1 - wtk) * r.pred_wtpn / 100)
    return T / 1e9


def fig3_contour(T, fname="fig3_welfare_contour.png"):
    """Net welfare surface, stacked at three levels of affective value."""
    grid = np.arange(1, 8)
    vmax = np.abs(T).max()
    levels = np.linspace(-vmax, vmax, 15)
    norm = TwoSlopeNorm(vmin=-vmax, vcenter=0, vmax=vmax)
    I, C = np.meshgrid(grid, grid)

    fig = plt.figure(figsize=(8, 6.5))
    ax = fig.add_subplot(111, projection="3d")
    for a in [1, 4, 7]:
        cf = ax.contourf(I, C, T[a - 1], zdir="z", offset=a, levels=levels,
                         cmap=CMAP, norm=norm, alpha=0.9)
        ax.contour(I, C, T[a - 1], zdir="z", offset=a, levels=levels,
                   colors="gray", linewidths=0.3)
        # zero line: disclosure is welfare-neutral
        ax.contour(I, C, T[a - 1], zdir="z", offset=a, levels=[0],
                   colors="black", linewidths=3)
    ax.set_xlabel("Instrumental value")
    ax.set_ylabel("Cognitive value")
    ax.set_zlabel("Affective value")
    ax.set_xticks(grid); ax.set_yticks(grid); ax.set_zticks([1, 4, 7])
    ax.set_xlim(1, 7); ax.set_ylim(1, 7); ax.set_zlim(0.7, 7.3)
    ax.view_init(elev=22, azim=-55)

    cb = fig.colorbar(cf, ax=ax, shrink=0.6, pad=0.10)
    cb.set_label("Net welfare (billion euros)")

    fig.tight_layout()
    fig.savefig(OUT / fname, dpi=300, bbox_inches="tight")


grid = load_value_grid()
K = contour_scaling(cells, PHI_MAIN)
T = contour_surface(grid, K)
print(f"K = {K/1e9:.1f} bn EUR   surface {T.min():.2f} to {T.max():.2f} bn")
fig3_contour(T)


# ---------------------------------------------------------------------------
# Sensitivity to the frequency parameter
# ---------------------------------------------------------------------------

def figA1_phi_sensitivity(d, freq):
    """One line per category over phi in [0, 1]."""
    rows = []
    for phi in PHI_GRID:
        c = for_figures(welfare_cells(d, freq, phi))
        s_ = c.groupby("product")["net"].sum() / 1e9
        for p in PRODUCT_ORDER:
            rows.append({"phi": phi, "product": p, "net": s_[p]})
    s = pd.DataFrame(rows)

    fig, ax = plt.subplots(figsize=(8.6, 4.8))
    cmap = plt.cm.viridis(np.linspace(0, 0.9, len(PRODUCT_ORDER)))
    for col, p in zip(cmap, PRODUCT_ORDER):
        y = s.loc[s["product"] == p].sort_values("phi")
        ax.plot(y["phi"], y["net"], color=col, lw=1.8, label=PRODUCT_LABEL[p])
        ax.annotate(PRODUCT_LABEL[p], xy=(1.0, y["net"].iloc[-1]),
                    xytext=(4, 0), textcoords="offset points",
                    color=col, fontsize=8, va="center")
    ax.set_yscale("log")
    ax.set_xlabel(r"Frequency-scaling parameter $\varphi$")
    ax.set_ylabel("Net welfare effect (billion euros, log scale)")
    ax.axvline(PHI_MAIN, color=GREY, lw=1.0, ls="--", zorder=0)
    ax.annotate(f"reported\n$\\varphi$ = {PHI_MAIN}", xy=(PHI_MAIN, ax.get_ylim()[1]),
                xytext=(3, -12), textcoords="offset points",
                fontsize=8, color=GREY, va="top")
    ax.set_xlim(0, 1.12)
    ax.set_xticks(np.arange(0, 1.01, 0.25))
    ax.legend(frameon=False, fontsize=8.5, ncol=2, loc="lower left")

    fig.tight_layout()
    fig.savefig(OUT / "figA1_phi_sensitivity.png", dpi=300, bbox_inches="tight")
    return s


s = figA1_phi_sensitivity(d, freq)


# ---------------------------------------------------------------------------
# Net welfare by country and category
# ---------------------------------------------------------------------------

def figA2_country_panels(cells):
    """One panel per country, shared y-axis."""
    c = for_figures(cells)
    fig, axes = plt.subplots(2, 3, figsize=(12, 6.4), sharey=True)
    pan = c.pivot_table(index="country", columns="product", values="net") / 1e9

    for ax, k in zip(axes.ravel(), COUNTRY_ORDER):
        vals = [pan.loc[k, p] for p in PRODUCT_ORDER]
        heights = vals + [sum(vals)]
        x = np.arange(len(heights))
        for xi, h, p in zip(x, heights, PRODUCT_ORDER + ["overall"]):
            ax.bar(xi, h, color=MAROON if p == "overall" else NAVY)
        ax.axhline(0, color="black", lw=0.6)
        ax.set_title(k, fontsize=10)
        ax.set_xticks(x)
        ax.set_xticklabels([PRODUCT_LABEL[p] for p in PRODUCT_ORDER] + ["Overall"],
                           rotation=60, ha="right", fontsize=7.5)

    for ax in axes[:, 0]:
        ax.set_ylabel("Net welfare (billion euros)", fontsize=9)

    fig.tight_layout()
    fig.savefig(OUT / "figA2_welfare_by_country_panels.png", dpi=300, bbox_inches="tight")


figA2_country_panels(cells)


# ---------------------------------------------------------------------------
# Welfare surface per product category
# ---------------------------------------------------------------------------

def figA3_product_contours(cells, path=DATA / "predictions_values_product.csv"):
    """Net welfare surface per product category, affective value fixed at 4."""
    if not Path(path).exists():
        print(f"  [skip] {path} not found")
        return

    gp = pd.read_csv(path)
    grid = np.arange(1, 8)
    I, C = np.meshgrid(grid, grid)

    fig, axes = plt.subplots(2, 4, figsize=(13, 6.4))
    flat = axes.ravel()
    for ax, p in zip(flat, PRODUCT_ORDER):
        sub = cells[cells["product"] == p]
        scale = sub["freq"] ** PHI_MAIN if PHI_MAIN > 0 else 1.0
        K = (sub["N"] * scale * sub["price_mean"]).sum()
        T = contour_surface(gp[gp["product"] == p], K)
        sl = T[3]                                   # affective value = 4
        vmax = np.abs(sl).max()
        norm = TwoSlopeNorm(vmin=-vmax, vcenter=0, vmax=vmax)
        cf = ax.contourf(I, C, sl, levels=np.linspace(-vmax, vmax, 15),
                         cmap=CMAP, norm=norm)
        if sl.min() < 0 < sl.max():
            ax.contour(I, C, sl, levels=[0], colors="black", linewidths=2)
        ax.set_title(PRODUCT_LABEL[p], fontsize=10)
        ax.set_xticks([1, 4, 7]); ax.set_yticks([1, 4, 7])
        ax.set_xlim(1, 7); ax.set_ylim(1, 7)
        cb = fig.colorbar(cf, ax=ax, shrink=0.85)
        cb.ax.tick_params(labelsize=7)

    for ax in flat[len(PRODUCT_ORDER):]:
        ax.axis("off")
    for ax in axes[1, :]:
        ax.set_xlabel("Instrumental value", fontsize=9)
    for ax in axes[:, 0]:
        ax.set_ylabel("Cognitive value", fontsize=9)

    fig.tight_layout()
    fig.savefig(OUT / "figA3_welfare_contour_by_product.png", dpi=300, bbox_inches="tight")


figA3_product_contours(cells)


# ---------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------

def appendix_table(cells, d, freq):
    """Panel A: country x category inputs and the net effect at PHI_MAIN (fur flagged).
    Panel B: aggregates by category, by country and overall at each reported phi.
    """
    a = cells.copy()
    a["N_m"] = a["N"] / 1e6
    a["net_m"] = a["net"] / 1e6
    a["reported"] = np.where(a["product"].isin(DROP_PRODUCTS), "no", "yes")
    a["product"] = a["product"].map(PRODUCT_LABEL)
    A = a[["country", "product", "n_decider", "N_m", "pi_plus", "mu_plus",
           "mu_minus", "price_mean", "freq", "net_m", "reported"]]
    A.columns = ["Country", "Product", "n (deciders)", "N (millions)",
                 "Share wanting info", "WTP receive (EUR)", "WTP avoid (EUR)",
                 "Mean price (EUR)", "Purchases per year",
                 f"Net welfare (EUR m, phi={PHI_MAIN})", "Reported"]
    A = A.sort_values(["Country", "Product"])
    A.round(3).to_csv(OUT / "tableA_welfare_inputs.csv", index=False)

    rows = []
    for phi in PHI_REPORT:
        c = for_figures(welfare_cells(d, freq, phi))
        by_p = c.groupby("product")["net"].sum() / 1e9
        by_k = c.groupby("country")["net"].sum()
        for p in PRODUCT_ORDER:
            rows.append({"Level": "Product", "Unit": PRODUCT_LABEL[p], "phi": phi,
                         "Net welfare (EUR bn)": by_p[p], "EUR per adult": np.nan})
        for k in COUNTRY_ORDER:
            rows.append({"Level": "Country", "Unit": k, "phi": phi,
                         "Net welfare (EUR bn)": by_k[k] / 1e9,
                         "EUR per adult": by_k[k] / ADULT_POP[k]})
        rows.append({"Level": "Total", "Unit": "Overall", "phi": phi,
                     "Net welfare (EUR bn)": c.net.sum() / 1e9,
                     "EUR per adult": c.net.sum() / sum(ADULT_POP.values())})
    B = (pd.DataFrame(rows)
         .pivot_table(index=["Level", "Unit"], columns="phi",
                      values=["Net welfare (EUR bn)", "EUR per adult"]))
    order = ([("Product", PRODUCT_LABEL[p]) for p in PRODUCT_ORDER] +
             [("Country", k) for k in COUNTRY_ORDER] + [("Total", "Overall")])
    B = B.reindex(order)
    B.round(3).to_csv(OUT / "tableB_welfare_aggregates.csv")
    return A, B


A, B = appendix_table(cells, d, freq)
print(A.head(8))
print(B)


def phi_table(d, freq, phis=PHI_REPORT):
    """Aggregate results at each reported phi."""
    rows = []
    for phi in phis:
        c = for_figures(welfare_cells(d, freq, phi))
        by_p = c.groupby("product")["net"].sum()
        by_k = c.groupby("country")["net"].sum()
        r = {"phi": phi,
             "overall_bn": c.net.sum() / 1e9,
             "benefit_bn": c.benefit.sum() / 1e9,
             "loss_bn": c.loss.sum() / 1e9,
             "benefit_loss_ratio": c.benefit.sum() / c.loss.sum(),
             "K_bn": contour_scaling(c, phi) / 1e9}
        for p in PRODUCT_ORDER:
            r[f"{p}_bn"] = by_p[p] / 1e9
        for k in COUNTRY_ORDER:
            r[f"{k}_bn"] = by_k[k] / 1e9
            r[f"{k}_eur_per_adult"] = by_k[k] / ADULT_POP[k]
        rows.append(r)
    t = pd.DataFrame(rows).set_index("phi")
    t.round(4).to_csv(OUT / "table_phi_sensitivity.csv")
    return t


pt = phi_table(d, freq)
print(pt[["overall_bn", "benefit_bn", "loss_bn", "benefit_loss_ratio", "K_bn"]].round(2))
print(pt[[f"{p}_bn" for p in PRODUCT_ORDER]].round(2))
print(pt[[f"{k}_eur_per_adult" for k in COUNTRY_ORDER]].round(2))


# ---------------------------------------------------------------------------
# Bootstrap confidence intervals
# Respondents are resampled within country in analysis.do; every draw is passed
# through Eq. (7). Populations, purchase frequencies and phi are held fixed.
# ---------------------------------------------------------------------------

BOOT_FILE = DATA / "welfare_inputs_bootstrap.csv"
CI = (2.5, 97.5)


def load_bootstrap(path=BOOT_FILE):
    """Bootstrap draws of the country x category inputs, one block per draw."""
    b = pd.read_csv(path)
    b["country"] = (b["country"].astype(str)
                    .str.replace(r"^\[\d+\]\s*", "", regex=True)
                    .replace({"USA": "US"}))
    b["adult_pop"] = b["country"].map(ADULT_POP)
    assert b["adult_pop"].notna().all(), "unmapped country in bootstrap file"
    b["N"] = b["adult_pop"] * b["decider_share_pop"]
    b = for_figures(b)
    # a cell without avoiders (or without wanters) in a draw has an undefined mean;
    # its share is zero, so its contribution is zero
    b["mu_plus"] = b["mu_plus"].fillna(0)
    b["mu_minus"] = b["mu_minus"].fillna(0)
    n = b.groupby("draw").size()
    assert n.nunique() == 1, "draws have different numbers of cells"
    return b.merge(freq, on=["country", "product"], how="left", validate="m:1")


def summarise(m, phi):
    """All reported quantities for one phi; m holds one or many draws."""
    scale = m["freq"] ** phi if phi > 0 else 1.0
    m = m.assign(benefit=m["N"] * scale * m["pi_plus"] * m["mu_plus"],
                 loss=m["N"] * scale * m["pi_minus"] * m["mu_minus"])
    m["net"] = m["benefit"] - m["loss"]
    tot = m.groupby("draw")[["net", "benefit", "loss"]].sum()
    out = pd.DataFrame({
        ("Total", "Overall", "Net welfare (EUR bn)"): tot["net"] / 1e9,
        ("Total", "Benefit", "Net welfare (EUR bn)"): tot["benefit"] / 1e9,
        ("Total", "Loss", "Net welfare (EUR bn)"): tot["loss"] / 1e9,
        ("Total", "Benefit-loss ratio", "Ratio"): tot["benefit"] / tot["loss"],
        ("Total", "Overall", "EUR per adult"): tot["net"] / sum(ADULT_POP.values()),
    })
    by_p = m.groupby(["draw", "product"])["net"].sum().unstack() / 1e9
    by_k = m.groupby(["draw", "country"])["net"].sum().unstack()
    for p in PRODUCT_ORDER:
        out[("Product", PRODUCT_LABEL[p], "Net welfare (EUR bn)")] = by_p[p]
    for k in COUNTRY_ORDER:
        out[("Country", k, "Net welfare (EUR bn)")] = by_k[k] / 1e9
        out[("Country", k, "EUR per adult")] = by_k[k] / ADULT_POP[k]
    return out


def bootstrap_table(d, boot, phis=PHI_REPORT):
    """Point estimate (full sample) with percentile interval, at each reported phi."""
    point_in = for_figures(d).merge(freq, on=["country", "product"],
                                    how="left", validate="1:1").assign(draw=0)
    rows = []
    for phi in phis:
        est = summarise(point_in, phi).iloc[0]
        bs = summarise(boot, phi)
        for key in bs.columns:
            lo, hi = np.percentile(bs[key], CI)
            rows.append({"Level": key[0], "Unit": key[1], "Measure": key[2],
                         "phi": phi, "Estimate": est[key], "Boot SE": bs[key].std(),
                         "CI low": lo, "CI high": hi})
    t = pd.DataFrame(rows)
    t.round(4).to_csv(OUT / "tableC_welfare_bootstrap_ci.csv", index=False)
    return t


def _ci_bars(ax, x, sub, units, fmt):
    est = sub.set_index("Unit").loc[units]
    err = np.vstack([est["Estimate"] - est["CI low"], est["CI high"] - est["Estimate"]])
    ax.errorbar(x, est["Estimate"], yerr=err, fmt="none", ecolor="black",
                elinewidth=1.0, capsize=3)
    for xi, h, top in zip(x, est["Estimate"], est["CI high"]):
        ax.text(xi, top + est["CI high"].max() * 0.015, format(h, fmt),
                ha="center", fontsize=8.5)
    ax.axhline(0, color="black", lw=0.8)
    ax.set_ylim(0, est["CI high"].max() * 1.12)
    ax.set_ylabel("Net welfare effect (billion euros)")
    return est


def fig1_by_category_ci(t, phi=PHI_MAIN):
    """Net welfare by category with 95% bootstrap intervals."""
    s = t[(t["phi"] == phi) & (t["Measure"] == "Net welfare (EUR bn)")]
    units = [PRODUCT_LABEL[p] for p in PRODUCT_ORDER] + ["Overall"]
    s = s[s["Level"].eq("Product") | (s["Level"].eq("Total") & s["Unit"].eq("Overall"))]
    x = np.arange(len(units))
    fig, ax = plt.subplots(figsize=(8.6, 4.6))
    est = s.set_index("Unit").loc[units]
    ax.bar(x, est["Estimate"], color=[NAVY] * len(PRODUCT_ORDER) + [MAROON], edgecolor="none")
    _ci_bars(ax, x, s, units, ".2f")
    ax.set_xticks(x); ax.set_xticklabels(units, fontsize=9.5)
    ax.legend(handles=[Patch(facecolor=NAVY, label="Product category"),
                       Patch(facecolor=MAROON, label="Overall (sum)")],
              loc="upper left", frameon=False, fontsize=8.5)
    fig.tight_layout()
    fig.savefig(OUT / "fig1_welfare_by_category_ci.png", dpi=300, bbox_inches="tight")


def fig2_by_country_ci(t, phi=PHI_MAIN):
    """Net welfare by country with 95% bootstrap intervals."""
    s = t[(t["phi"] == phi) & (t["Measure"] == "Net welfare (EUR bn)") & (t["Level"] == "Country")]
    x = np.arange(len(COUNTRY_ORDER))
    fig, ax = plt.subplots(figsize=(7.2, 4.2))
    est = s.set_index("Unit").loc[COUNTRY_ORDER]
    ax.bar(x, est["Estimate"], color=NAVY, edgecolor="none")
    _ci_bars(ax, x, s, COUNTRY_ORDER, ".2f")
    ax.set_xticks(x); ax.set_xticklabels(COUNTRY_ORDER)
    fig.tight_layout()
    fig.savefig(OUT / "fig2_welfare_by_country_ci.png", dpi=300, bbox_inches="tight")


boot = load_bootstrap()
print(f"bootstrap draws: {boot['draw'].nunique()}")
tC = bootstrap_table(d, boot)

head = tC[tC["Level"] == "Total"].pivot_table(index=["Unit", "Measure"], columns="phi",
                                              values=["Estimate", "CI low", "CI high"])
print(head.round(2))
print(tC[(tC["Level"] == "Country") & (tC["Measure"] == "EUR per adult")]
      .pivot_table(index="Unit", columns="phi", values=["Estimate", "CI low", "CI high"]).round(2))

fig1_by_category_ci(tC)
fig2_by_country_ci(tC)

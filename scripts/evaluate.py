# Evaluate saved predictions and generate plots
#
# Expects:
#   results/predictions_logreg.csv  (columns: y_true, y_pred)
#   results/predictions_xgb.csv     (columns: y_true, y_pred)
#
# Produces:
#   results/figures/roc_<model>.png
#   results/figures/pr_<model>.png
#   results/figures/calibration_<model>.png
#
# Also prints AUROC, AUPRC, Brier, and P@80%R + NNE@80%R.

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

from sklearn.metrics import (
    roc_auc_score,
    roc_curve,
    average_precision_score,
    precision_recall_curve,
    brier_score_loss,
)
from sklearn.calibration import calibration_curve


def precision_at_recall(y_true: np.ndarray, y_pred: np.ndarray, target_recall: float = 0.80):
    """
    Returns:
      (precision, recall, threshold)

    Uses the PR curve and selects the point with recall >= target_recall
    that is closest to target_recall (from above).
    """
    precision, recall, thresholds = precision_recall_curve(y_true, y_pred)

    # precision and recall have length N+1; thresholds length N
    # We'll align threshold with precision/recall by using indices 0..N-1
    if len(thresholds) == 0:
        return float("nan"), float("nan"), float("nan")

    recall_t = recall[:-1]
    precision_t = precision[:-1]

    valid = np.where(recall_t >= target_recall)[0]
    if len(valid) == 0:
        return float("nan"), float(recall_t.max()), float("nan")

    # Choose the recall just above the target (closest from above)
    i = valid[np.argmin(recall_t[valid] - target_recall)]
    return float(precision_t[i]), float(recall_t[i]), float(thresholds[i])


def plot_roc(y_true, y_pred, outpath: Path, title: str):
    fpr, tpr, _ = roc_curve(y_true, y_pred)
    auroc = roc_auc_score(y_true, y_pred)

    plt.figure()
    plt.plot(fpr, tpr, label=f"AUROC = {auroc:.3f}")
    plt.plot([0, 1], [0, 1], linestyle="--", label="Chance")
    plt.xlabel("False Positive Rate")
    plt.ylabel("True Positive Rate")
    plt.title(title)
    plt.legend(loc="lower right")
    plt.tight_layout()
    plt.savefig(outpath, dpi=200)
    plt.close()


def plot_pr(y_true, y_pred, outpath: Path, title: str):
    precision, recall, _ = precision_recall_curve(y_true, y_pred)
    auprc = average_precision_score(y_true, y_pred)

    plt.figure()
    plt.plot(recall, precision, label=f"AUPRC = {auprc:.3f}")
    plt.xlabel("Recall")
    plt.ylabel("Precision")
    plt.title(title)
    plt.legend(loc="lower left")
    plt.tight_layout()
    plt.savefig(outpath, dpi=200)
    plt.close()


def plot_calibration(y_true, y_pred, outpath: Path, title: str, n_bins: int = 10):
    frac_pos, mean_pred = calibration_curve(y_true, y_pred, n_bins=n_bins, strategy="uniform")

    plt.figure()
    plt.plot(mean_pred, frac_pos, marker="o", label="Model")
    plt.plot([0, 1], [0, 1], linestyle="--", label="Perfectly calibrated")
    plt.xlabel("Mean predicted probability")
    plt.ylabel("Fraction of positives")
    plt.title(title)
    plt.legend(loc="upper left")
    plt.tight_layout()
    plt.savefig(outpath, dpi=200)
    plt.close()


def evaluate_one(pred_file: Path, figures_dir: Path, model_name: str, target_recall: float = 0.80):
    df = pd.read_csv(pred_file)
    if not {"y_true", "y_pred"}.issubset(df.columns):
        raise ValueError(f"{pred_file} must contain columns: y_true, y_pred")

    y_true = df["y_true"].to_numpy().astype(int)
    y_pred = df["y_pred"].to_numpy().astype(float)

    auroc = roc_auc_score(y_true, y_pred)
    auprc = average_precision_score(y_true, y_pred)
    brier = brier_score_loss(y_true, y_pred)

    p_at_r, r_at_r, thr = precision_at_recall(y_true, y_pred, target_recall=target_recall)
    nne = (1.0 / p_at_r) if (p_at_r is not None and np.isfinite(p_at_r) and p_at_r > 0) else float("inf")

    plot_roc(y_true, y_pred, figures_dir / f"roc_{model_name}.png", f"ROC — {model_name}")
    plot_pr(y_true, y_pred, figures_dir / f"pr_{model_name}.png", f"Precision–Recall — {model_name}")
    plot_calibration(y_true, y_pred, figures_dir / f"calibration_{model_name}.png", f"Calibration — {model_name}")

    print(f"\nEvaluating: {model_name}")
    print(f"  AUROC: {auroc:.3f}")
    print(f"  AUPRC: {auprc:.3f}")
    print(f"  Brier: {brier:.3f}")
    if np.isfinite(p_at_r):
        print(f"  P@{int(target_recall*100)}%R: {p_at_r:.3f}  (recall={r_at_r:.3f}, thr={thr:.4f}, NNE={nne:.1f})")
    else:
        print(f"  P@{int(target_recall*100)}%R: n/a (could not reach recall={target_recall:.2f})")

    return {
        "auroc": float(auroc),
        "auprc": float(auprc),
        "brier": float(brier),
        "p_at_target_recall": float(p_at_r) if np.isfinite(p_at_r) else None,
        "target_recall": float(target_recall),
        "threshold_at_target_recall": float(thr) if np.isfinite(p_at_r) else None,
        "nne_at_target_recall": float(nne) if np.isfinite(p_at_r) else None,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--results-dir", default="results", help="Path to results directory")
    parser.add_argument("--target-recall", type=float, default=0.80, help="Recall level for P@R metric")
    args = parser.parse_args()

    base = Path(__file__).resolve().parents[1]
    results_dir = (base / args.results_dir).resolve()
    figures_dir = results_dir / "figures"
    figures_dir.mkdir(parents=True, exist_ok=True)

    candidates = [
        ("logreg", results_dir / "predictions_logreg.csv"),
        ("xgb", results_dir / "predictions_xgb.csv"),
    ]

    any_found = False
    summary = {}

    for name, pred_path in candidates:
        if pred_path.exists():
            any_found = True
            summary[name] = evaluate_one(pred_path, figures_dir, name, target_recall=args.target_recall)
        else:
            print(f"Skipping {name}: missing {pred_path}")

    if not any_found:
        raise FileNotFoundError(
            "No prediction files found. Run:\n"
            "  python scripts/train_logreg.py\n"
            "  python scripts/train_xgboost.py\n"
            "Then run:\n"
            "  python scripts/evaluate.py"
        )

    print("\nSummary:")
    for name, m in summary.items():
        p = m["p_at_target_recall"]
        nne = m["nne_at_target_recall"]
        if p is None:
            p_str = "n/a"
            nne_str = "n/a"
        else:
            p_str = f"{p:.3f}"
            nne_str = f"{nne:.1f}"
        print(
            f"  {name:6s} | AUROC: {m['auroc']:.3f} | AUPRC: {m['auprc']:.3f} | "
            f"Brier: {m['brier']:.3f} | P@{int(m['target_recall']*100)}%R: {p_str} | NNE@{int(m['target_recall']*100)}%R: {nne_str}"
        )


if __name__ == "__main__":
    main()

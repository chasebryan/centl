// CentL ASCII/Unicode 2D Function Plotter
// Free Computation Foundation - Apache-2.0

use crate::engine::symbolic::Parser;
use crate::engine::{eval_expr, Expr, Session};

/// Parses plot command syntax:
/// e.g. "plot sin(x) from -3.14 to 3.14"
/// e.g. "plot x^2 - 4 from -5 to 5"
/// e.g. "plot cos(x)" (defaults -6.28 to 6.28)
pub fn handle_plot_command(cmd: &str) -> Result<String, String> {
    let had_outer_paren = cmd.trim().starts_with("plot(") && cmd.trim().ends_with(')');
    let stripped = if had_outer_paren {
        let inner = cmd.trim().strip_prefix("plot(").unwrap().strip_suffix(')').unwrap();
        inner.trim()
    } else {
        cmd.trim().strip_prefix("plot ").unwrap_or(cmd.trim()).trim()
    };

    let (expr_str, x_min, x_max) = if let Some(from_idx) = stripped.to_lowercase().find(" from ") {
        let expr = stripped[..from_idx].trim();
        let rest = stripped[from_idx + 6..].trim();
        if let Some(to_idx) = rest.to_lowercase().find(" to ") {
            let min_str = rest[..to_idx].trim();
            let max_str = rest[to_idx + 4..].trim();
            let min_val: f64 = min_str.parse().map_err(|_| format!("invalid x_min value: {}", min_str))?;
            let max_val: f64 = max_str.parse().map_err(|_| format!("invalid x_max value: {}", max_str))?;
            (expr, min_val, max_val)
        } else {
            (expr, -5.0, 5.0)
        }
    } else {
        (stripped, -6.28, 6.28)
    };

    generate_ascii_plot(expr_str, x_min, x_max, 50, 15)
}

pub fn generate_ascii_plot(
    expr_str: &str,
    x_min: f64,
    x_max: f64,
    width: usize,
    height: usize,
) -> Result<String, String> {
    if x_min >= x_max {
        return Err("x_min must be strictly less than x_max".to_string());
    }
    let width = width.clamp(20, 80);
    let height = height.clamp(8, 25);
    let expr = Parser::parse(expr_str)?;
    let mut session = Session::new();

    let mut points: Vec<(f64, f64)> = Vec::with_capacity(width);
    let mut y_min = f64::INFINITY;
    let mut y_max = f64::NEG_INFINITY;

    for i in 0..width {
        let t = (i as f64) / ((width - 1) as f64);
        let x = x_min + t * (x_max - x_min);
        let rat = crate::engine::rational::BigRational::from_f64(x).unwrap_or_else(crate::engine::rational::BigRational::zero);
        session.variables.insert("x".to_string(), Expr::Number(rat));

        let y_val = match eval_expr(&expr, &session) {
            Ok(e) => e.to_f64().unwrap_or(f64::NAN),
            _ => f64::NAN,
        };

        if !y_val.is_nan() && !y_val.is_infinite() {
            if y_val < y_min {
                y_min = y_val;
            }
            if y_val > y_max {
                y_max = y_val;
            }
            points.push((x, y_val));
        } else {
            points.push((x, f64::NAN));
        }
    }

    if y_min.is_infinite() || y_max.is_infinite() {
        return Err("expression produced no finite numerical values in the specified interval".to_string());
    }
    if (y_max - y_min).abs() < 1e-9 {
        y_max += 1.0;
        y_min -= 1.0;
    }

    let mut grid = vec![vec![' '; width]; height];

    // Mark zero axis lines if within bounds
    if y_min <= 0.0 && y_max >= 0.0 {
        let zero_norm = (0.0 - y_min) / (y_max - y_min);
        let zero_row = ((height - 1) as f64 * (1.0 - zero_norm)).round() as usize;
        let zero_row = zero_row.min(height - 1);
        for col in 0..width {
            grid[zero_row][col] = '·';
        }
    }

    // Plot points
    for (i, &(_, y)) in points.iter().enumerate() {
        if !y.is_nan() {
            let norm_y = (y - y_min) / (y_max - y_min);
            let row = ((height - 1) as f64 * (1.0 - norm_y)).round() as usize;
            let row_clamped = row.min(height - 1);
            grid[row_clamped][i] = '●';
        }
    }

    // Render output string
    let mut out = String::new();
    out.push_str(&format!("Function Plot: f(x) = {}\n", expr_str));
    out.push_str(&format!("Domain: x ∈ [{:.4}, {:.4}]  |  Range: y ∈ [{:.4}, {:.4}]\n", x_min, x_max, y_min, y_max));
    out.push_str(&format!("┌{}┐\n", "─".repeat(width)));
    for r in 0..height {
        let label = if r == 0 {
            format!("{:>8.2} │", y_max)
        } else if r == height / 2 {
            format!("{:>8.2} │", (y_max + y_min) / 2.0)
        } else if r == height - 1 {
            format!("{:>8.2} │", y_min)
        } else {
            "         │".to_string()
        };
        let row_str: String = grid[r].iter().collect();
        out.push_str(&format!("{}{}\n", label, row_str));
    }
    out.push_str(&format!("└{}┘\n", "─".repeat(width)));
    out.push_str(&format!("          {:<10.2}{:>width$}\n", x_min, format!("{:.2}", x_max), width = width.saturating_sub(10)));

    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ascii_plot_generation() {
        let plot = generate_ascii_plot("sin(x)", -3.14, 3.14, 40, 10).unwrap();
        assert!(plot.contains("Function Plot: f(x) = sin(x)"));
        assert!(plot.contains("●"));
    }

    #[test]
    fn test_handle_plot_command() {
        let res = handle_plot_command("plot x^2 from -4 to 4").unwrap();
        assert!(res.contains("Function Plot: f(x) = x^2"));
    }
}

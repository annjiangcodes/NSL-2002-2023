# CREATE LEGACY VS CORRECTED PANELS - Aug 8, 2025
# Requires: magick

suppressPackageStartupMessages({
  library(magick)
  library(fs)
})

message("=== CREATE LEGACY VS CORRECTED PANELS (Aug 8, 2025) ===")

# Define legacy->corrected pairs (absolute paths when needed)
legacy_pairs <- list(
  list(
    legacy = "/Users/ajiang/Documents/Research/Immigrants against Immigrants?/NSL Project/NSL-2002-2023/outputs/figure_v4_4_main_generation_trends.png",
    corrected = "current/outputs/CURRENT_2025_08_08_FIGURES_conference/1_main_generational_trends_CORRECTED.png",
    out = "current/outputs/CURRENT_2025_08_08_FIGURES_conference/panel_v4_4_vs_corrected_main_trends.png",
    legacy_label = "Legacy v4.4 pre-correction",
    corrected_label = "Corrected (v2.9w+) 2025-08-08"
  ),
  list(
    legacy = "/Users/ajiang/Documents/Research/Immigrants against Immigrants?/NSL Project/NSL-2002-2023/outputs/figure_v4_1_magnified_generation_trends.png",
    corrected = "current/outputs/CURRENT_2025_08_08_FIGURES_conference/2_volatility_comparison_CORRECTED.png",
    out = "current/outputs/CURRENT_2025_08_08_FIGURES_conference/panel_v4_1_vs_corrected_volatility.png",
    legacy_label = "Legacy v4.1 pre-correction",
    corrected_label = "Corrected (v2.9w+) 2025-08-08"
  )
)

# Ensure output dir exists
dir_create("current/outputs/CURRENT_2025_08_08_FIGURES_conference")

safe_stamp <- function(img, text, gravity = "southwest", size = 28, color = "white") {
  # Minimal annotation to avoid MVG errors
  tryCatch({
    image_annotate(img, text = text, gravity = gravity, size = size, color = color)
  }, error = function(e) {
    # Fallback: return original image without stamp
    img
  })
}

compose_panel <- function(legacy_path, corrected_path, out_path, legacy_label, corrected_label) {
  if (!file_exists(legacy_path)) {
    message("SKIP (legacy missing): ", legacy_path)
    return(FALSE)
  }
  if (!file_exists(corrected_path)) {
    message("SKIP (corrected missing): ", corrected_path)
    return(FALSE)
  }
  
  legacy_img <- image_read(legacy_path)
  corrected_img <- image_read(corrected_path)
  
  # Stamp captions (simple, to avoid MVG errors)
  legacy_img <- safe_stamp(legacy_img, legacy_label)
  corrected_img <- safe_stamp(corrected_img, paste0(corrected_label, " | Corrected as of 2025-08-08"))
  
  # Match heights
  target_h <- min(image_info(legacy_img)$height, image_info(corrected_img)$height)
  legacy_img <- image_resize(legacy_img, geometry = paste0("x", target_h))
  corrected_img <- image_resize(corrected_img, geometry = paste0("x", target_h))
  
  panel <- image_append(c(legacy_img, corrected_img))
  image_write(panel, out_path)
  message("CREATED: ", out_path)
  TRUE
}

for (p in legacy_pairs) {
  compose_panel(p$legacy, p$corrected, p$out, p$legacy_label, p$corrected_label)
}

message("=== DONE CREATING LEGACY VS CORRECTED PANELS ===")

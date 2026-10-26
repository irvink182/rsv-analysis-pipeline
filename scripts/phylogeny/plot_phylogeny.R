#!/usr/bin/env Rscript

###############################################################################
# Generic annotated phylogeny plot
#
# Plot a phylogenetic tree together with metadata annotations.
#
# Supported features:
#   - Newick trees
#   - TSV metadata
#   - Optional rooting using a specified taxon
#   - Optional tip colouring
#   - Multiple metadata annotation tracks
#   - Discrete and continuous annotations
#   - Rectangular or circular layout
#   - PNG and SVG output
###############################################################################


###############################################################################
# Libraries
###############################################################################

suppressPackageStartupMessages({
    library(optparse)
    library(dplyr)
    library(readr)
    library(ggplot2)
    library(ape)
    library(ggtree)
    library(ggtreeExtra)
    library(ggnewscale)
})


###############################################################################
# Command-line arguments
###############################################################################

option_list <- list(

    make_option(
        "--tree",
        dest = "tree",
        type = "character",
        help = "Input phylogenetic tree in Newick format."
    ),

    make_option(
        "--metadata",
        dest = "metadata",
        type = "character",
        help = "Metadata table in TSV format."
    ),

    make_option(
        "--taxon-column",
        dest = "taxon_column",
        type = "character",
        help = paste(
            "Metadata column containing taxon names",
            "matching the tree tip labels."
        )
    ),

    make_option(
        "--root",
        dest = "root",
        type = "character",
        default = NULL,
        help = paste(
            "Optional taxon to use as outgroup for rooting."
        )
    ),

    make_option(
        "--color",
        dest = "color",
        type = "character",
        default = NULL,
        help = paste(
            "Optional metadata column used to colour tip points."
        )
    ),

    make_option(
        "--annotation",
        dest = "annotation",
        type = "character",
        action = "append",
        default = NULL,
        help = paste(
            "Metadata annotation track.",
            "Format: COLUMN:TYPE[:LABEL], where TYPE is",
            "'categorical', 'binary' or 'continuous'.",
            "'discrete' is accepted as an alias of 'categorical'.",
            "Can be specified multiple times."
        )
    ),

    make_option(
        "--layout",
        dest = "layout",
        type = "character",
        default = "rectangular",
        help = paste(
            "Tree layout: rectangular or circular",
            "[default: %default]."
        )
    ),

    make_option(
        "--output",
        dest = "output",
        type = "character",
        help = "Output file prefix."
    ),

    make_option(
        "--width",
        dest = "width",
        type = "double",
        default = 11,
        help = "Figure width in inches [default: %default]."
    ),

    make_option(
        "--height",
        dest = "height",
        type = "double",
        default = 12,
        help = "Figure height in inches [default: %default]."
    ),

    make_option(
        "--dpi",
        dest = "dpi",
        type = "integer",
        default = 300,
        help = "PNG resolution [default: %default]."
    )
)


parser <- OptionParser(
    option_list = option_list,
    description = paste(
        "Generate an annotated phylogenetic tree",
        "from a Newick tree and metadata table."
    )
)

args <- parse_args(parser)


###############################################################################
# Validate required arguments
###############################################################################

required_arguments <- c(
    "tree",
    "metadata",
    "taxon_column",
    "output"
)

missing_arguments <- required_arguments[
    vapply(
        required_arguments,
        function(x) {
            is.null(args[[x]]) || args[[x]] == ""
        },
        logical(1)
    )
]

if (length(missing_arguments) > 0) {

    stop(
        paste0(
            "Missing required argument(s): ",
            paste(
                paste0("--", gsub("_", "-", missing_arguments)),
                collapse = ", "
            )
        ),
        call. = FALSE
    )
}


###############################################################################
# Validate files
###############################################################################

if (!file.exists(args$tree)) {

    stop(
        paste0(
            "Tree file not found: ",
            args$tree
        ),
        call. = FALSE
    )
}

if (!file.exists(args$metadata)) {

    stop(
        paste0(
            "Metadata file not found: ",
            args$metadata
        ),
        call. = FALSE
    )
}


###############################################################################
# Validate layout
###############################################################################

valid_layouts <- c(
    "rectangular",
    "circular"
)

if (!args$layout %in% valid_layouts) {

    stop(
        paste0(
            "Invalid layout '",
            args$layout,
            "'. Valid options: ",
            paste(valid_layouts, collapse = ", ")
        ),
        call. = FALSE
    )
}

###############################################################################
# Layout-specific plotting parameters
###############################################################################

if (args$layout == "rectangular") {

    tip_size <- 1.6
    reference_size <- 2.0

    track_width <- 0.008
    track_spacing <- 0.05

    lineage_legend_ncol <- 2

} else if (args$layout == "circular") {

    tip_size <- 0.5
    reference_size <- 0.8

    track_width <- 0.012
    track_spacing <- 0.02

    lineage_legend_ncol <- 8
}

###############################################################################
# Colour palettes
###############################################################################

# Glasbey palette for categorical variables.
# Designed for datasets containing many distinct categories.
glasbey_palette <- c(
    "#0000FF", "#FF0000", "#00A000", "#000033",
    "#FF00B6", "#005300", "#FFD300", "#009FFF",
    "#9A4D42", "#00FFBE", "#783FC1", "#1F9698",
    "#FFACFD", "#B1CC71", "#F1085C", "#FE8F42",
    "#DD00FF", "#201A01", "#720055", "#766C95",
    "#02AD24", "#C8FF00", "#886C00", "#FFB79F",
    "#858567", "#A10300", "#14F9FF", "#00479E",
    "#DC5E93", "#93D4FF", "#004C3B", "#5A026B",
    "#AF8CFF", "#5C7300", "#FF7ED1", "#15B7A5",
    "#7E6405", "#BC2D75", "#7D0000", "#FF9A00",
    "#00FF7C", "#FF6E41", "#6B3A00", "#7A7AFF",
    "#00C6FF", "#B97A57", "#8A005D", "#4C8C2B",
    "#FF3B9D", "#00A6A6", "#D4A6FF", "#8B8B00",
    "#A65CFF", "#006B54", "#E1B400", "#6E1B52",
    "#A6FF00", "#0055D4", "#D85A00", "#00D4A6",
    "#B80000", "#7B5DFF", "#5A8F00", "#FF5AD4"
)

# Set1 palette for binary variables.
set1_palette <- c(
    "#E41A1C",
    "#377EB8"
)


###############################################################################
# Categorical colours
###############################################################################

get_categorical_colors <- function(values) {

    categories <- sort(
        unique(
            as.character(
                values[!is.na(values)]
            )
        )
    )

    non_singletons <- categories[
        categories != "Singleton"
    ]

    if (length(non_singletons) > length(glasbey_palette)) {

        stop(
            paste0(
                "Too many categories for the Glasbey palette: ",
                length(non_singletons),
                ". Maximum supported: ",
                length(glasbey_palette),
                "."
            ),
            call. = FALSE
        )
    }

    colours <- glasbey_palette[
        seq_along(non_singletons)
    ]

    names(colours) <- non_singletons

    # Always display singletons using a neutral colour.
    if ("Singleton" %in% categories) {

        colours <- c(
            colours,
            "Singleton" = "grey80"
        )
    }

    colours
}


###############################################################################
# Binary colours
###############################################################################

get_binary_colors <- function(values) {

    categories <- sort(
        unique(
            as.character(
                values[!is.na(values)]
            )
        )
    )

    if (length(categories) > 2) {

        stop(
            paste0(
                "Variable declared as binary contains ",
                length(categories),
                " categories: ",
                paste(categories, collapse = ", ")
            ),
            call. = FALSE
        )
    }

    colours <- set1_palette[
        seq_along(categories)
    ]

    names(colours) <- categories

    colours
}

###############################################################################
# Tree scale helper
###############################################################################

nice_scale <- function(x) {

    exponent <- floor(log10(x))
    fraction <- x / (10 ^ exponent)

    nice_fraction <- if (
        fraction < 1.5
    ) {
        1
    } else if (
        fraction < 3
    ) {
        2
    } else if (
        fraction < 7
    ) {
        5
    } else {
        10
    }

    nice_fraction * (10 ^ exponent)
}

###############################################################################
# Read tree
###############################################################################

tree <- ape::read.tree(
    args$tree
)

if (is.null(tree)) {

    stop(
        "Unable to read phylogenetic tree.",
        call. = FALSE
    )
}

if (anyDuplicated(tree$tip.label)) {

    duplicated_tips <- unique(
        tree$tip.label[
            duplicated(tree$tip.label)
        ]
    )

    stop(
        paste0(
            "Duplicated tip labels detected: ",
            paste(duplicated_tips, collapse = ", ")
        ),
        call. = FALSE
    )
}


###############################################################################
# Root tree
###############################################################################

if (!is.null(args$root)) {

    if (!args$root %in% tree$tip.label) {

        stop(
            paste0(
                "Root taxon '",
                args$root,
                "' was not found in the tree."
            ),
            call. = FALSE
        )
    }

    cat(
        "Rooting tree using taxon:\n",
        "    ", args$root, "\n\n",
        sep = ""
    )

    tree <- ape::root(
        tree,
        outgroup = args$root,
        resolve.root = TRUE
    )
}


###############################################################################
# Read metadata
###############################################################################

metadata <- readr::read_tsv(
    args$metadata,
    show_col_types = FALSE
)


###############################################################################
# Validate metadata
###############################################################################

if (!args$taxon_column %in% colnames(metadata)) {

    stop(
        paste0(
            "Taxon column '",
            args$taxon_column,
            "' was not found in metadata."
        ),
        call. = FALSE
    )
}

if (anyDuplicated(metadata[[args$taxon_column]])) {

    duplicated_taxa <- unique(
        metadata[[args$taxon_column]][
            duplicated(metadata[[args$taxon_column]])
        ]
    )

    stop(
        paste0(
            "Duplicated taxa in metadata column '",
            args$taxon_column,
            "': ",
            paste(duplicated_taxa, collapse = ", ")
        ),
        call. = FALSE
    )
}


###############################################################################
# Validate requested metadata columns
###############################################################################

requested_columns <- character(0)

if (!is.null(args$color)) {
    requested_columns <- c(
        requested_columns,
        args$color
    )
}


###############################################################################
# Parse annotations
###############################################################################

annotations <- list()

if (!is.null(args$annotation)) {

    for (annotation in args$annotation) {

        fields <- strsplit(
            annotation,
            ":",
            fixed = TRUE
        )[[1]]

        if (!length(fields) %in% c(2, 3)) {

            stop(
                paste0(
                    "Invalid annotation specification: '",
                    annotation,
                    "'. Expected COLUMN:TYPE or COLUMN:TYPE:LABEL."
                ),
                call. = FALSE
            )
        }

        column <- fields[1]
        type <- fields[2]

        if (!type %in% c(
            "discrete",
            "categorical",
            "binary",
            "continuous"
        )) {
            stop(
                paste0(
                    "Invalid annotation type '",
                    type,
                    "' for column '",
                    column,
                    "'. Use categorical, binary or continuous."
                ),
                call. = FALSE
            )
        }

        # Backwards compatibility:
        # treat 'discrete' as an alias of 'categorical'.
        if (type == "discrete") {
            type <- "categorical"
        }

        # Use custom label when provided.
        # Otherwise use the original column name.
        if (length(fields) == 3) {
            label <- fields[3]
        } else {
            label <- column
        }

        annotations[[length(annotations) + 1]] <- list(
            column = column,
            type = type,
            label = label
        )

        requested_columns <- c(
            requested_columns,
            column
        )
    }
}


###############################################################################
# Check requested columns
###############################################################################

missing_columns <- setdiff(
    unique(requested_columns),
    colnames(metadata)
)

if (length(missing_columns) > 0) {

    stop(
        paste0(
            "Metadata column(s) not found: ",
            paste(missing_columns, collapse = ", ")
        ),
        call. = FALSE
    )
}


###############################################################################
# Prepare metadata
###############################################################################

meta_tree <- metadata %>%

    filter(
        .data[[args$taxon_column]]
        %in%
        tree$tip.label
    ) %>%

    rename(
        label = all_of(args$taxon_column)
    )


###############################################################################
# Metadata/tree QC
###############################################################################

missing_metadata <- setdiff(
    tree$tip.label,
    meta_tree$label
)

missing_tree <- setdiff(
    metadata[[args$taxon_column]],
    tree$tip.label
)


cat("\n")
cat("============================================================\n")
cat("Phylogeny metadata QC\n")
cat("============================================================\n")
cat("\n")

cat(
    sprintf(
        "%-35s %10d\n",
        "Tips in tree",
        length(tree$tip.label)
    )
)

cat(
    sprintf(
        "%-35s %10d\n",
        "Metadata rows",
        nrow(metadata)
    )
)

cat(
    sprintf(
        "%-35s %10d\n",
        "Matched tips",
        nrow(meta_tree)
    )
)

cat(
    sprintf(
        "%-35s %10d\n",
        "Tree tips without metadata",
        length(missing_metadata)
    )
)

cat(
    sprintf(
        "%-35s %10d\n",
        "Metadata rows absent from tree",
        length(missing_tree)
    )
)

cat("\n")


if (length(missing_metadata) > 0) {

    cat("Tree tips without metadata:\n")

    for (taxon in missing_metadata) {
        cat("    ", taxon, "\n", sep = "")
    }

    cat("\n")
}


if (length(missing_tree) > 0) {

    cat("Metadata taxa absent from tree:\n")

    for (taxon in missing_tree) {
        cat("    ", taxon, "\n", sep = "")
    }

    cat("\n")
}


###############################################################################
# Base tree
###############################################################################

p <- ggtree(
    tree,
    layout = args$layout,
    linewidth = 0.3
)

###############################################################################
# Tree scale
###############################################################################

# Calculate a suitable scale width from the maximum root-to-tip distance.
# The same scale value is used for rectangular and circular layouts.

tip_depths <- ape::node.depth.edgelength(tree)[
    seq_len(length(tree$tip.label))
]

tree_depth <- max(
    tip_depths,
    na.rm = TRUE
)

scale_width <- nice_scale(
    tree_depth / 5
)


###############################################################################
# Rectangular layout
###############################################################################

if (args$layout == "rectangular") {

    scale_y <- length(tree$tip.label) + 0.5

    p <- p +
        ggtree::geom_treescale(
            x = 0,
            y = scale_y,
            width = scale_width,
            fontsize = 3
        )
}


###############################################################################
# Circular layout
###############################################################################

scale_grob <- NULL

if (args$layout == "circular") {

    scale_label <- format(
        scale_width,
        scientific = FALSE,
        trim = TRUE
    )

    scale_grob <- grid::grobTree(

        #######################################################################
        # Horizontal scale bar
        #######################################################################

        grid::segmentsGrob(
            x0 = grid::unit(0.12, "npc"),
            x1 = grid::unit(0.20, "npc"),
            y0 = grid::unit(0.88, "npc"),
            y1 = grid::unit(0.88, "npc"),
            gp = grid::gpar(
                col = "black",
                lwd = 1
            )
        ),

        #######################################################################
        # Left tick
        #######################################################################

        grid::segmentsGrob(
            x0 = grid::unit(0.12, "npc"),
            x1 = grid::unit(0.12, "npc"),
            y0 = grid::unit(0.875, "npc"),
            y1 = grid::unit(0.885, "npc"),
            gp = grid::gpar(
                col = "black",
                lwd = 1
            )
        ),

        #######################################################################
        # Right tick
        #######################################################################

        grid::segmentsGrob(
            x0 = grid::unit(0.20, "npc"),
            x1 = grid::unit(0.20, "npc"),
            y0 = grid::unit(0.875, "npc"),
            y1 = grid::unit(0.885, "npc"),
            gp = grid::gpar(
                col = "black",
                lwd = 1
            )
        ),

        #######################################################################
        # Scale label
        #######################################################################

        grid::textGrob(
            label = scale_label,
            x = grid::unit(0.16, "npc"),
            y = grid::unit(0.895, "npc"),
            gp = grid::gpar(
                fontsize = 7
            )
        )
    )
}


###############################################################################
# Attach metadata required for tip points
###############################################################################

if (!is.null(args$color)) {

    tip_metadata <- meta_tree %>%
        dplyr::select(
            label,
            all_of(args$color)
        )

    p <- p %<+% tip_metadata
}


###############################################################################
# Tip points
###############################################################################

if (!is.null(args$color)) {

    color_column <- args$color

    color_mapping <- ggplot2::aes()

    color_mapping$colour <- rlang::sym(
        color_column
    )

    tip_colors <- get_categorical_colors(
        tip_metadata[[color_column]]
    )

    p <- p +
        ggtree::geom_tippoint(
            data = function(x) {
                dplyr::filter(
                    x,
                    !is.na(.data[[color_column]])
                )
            },
            mapping = color_mapping,
            size = tip_size
        ) +
        ggplot2::scale_color_manual(
            name = color_column,
            values = tip_colors,
            na.value = "grey50",
            na.translate = FALSE,
            guide = ggplot2::guide_legend(
                order = 1,
                ncol = lineage_legend_ncol,
                byrow = TRUE
            )
        )
}

###############################################################################
# Highlight root/reference taxon
###############################################################################

if (!is.null(args$root)) {

    p <- p +
        ggtree::geom_tippoint(
            data = function(x) {
                dplyr::filter(
                    x,
                    label == args$root
                )
            },
            ggplot2::aes(
                shape = "Reference"
            ),
            color = "grey40",
            size = reference_size
        ) +
        ggplot2::scale_shape_manual(
            name = NULL,
            values = c(
                "Reference" = 16
            ),
            guide = ggplot2::guide_legend(
                order = 2
            )
        )
}

###############################################################################
# Metadata annotation tracks
###############################################################################

track_labels <- character()

if (length(annotations) > 0) {

    for (i in seq_along(annotations)) {

        annotation <- annotations[[i]]

        column <- annotation$column
        type <- annotation$type
        annotation_label <- annotation$label

        annotation_order <- i + 2

        track_labels <- c(
            track_labels,
            annotation_label
        )


        #######################################################################
        # Prepare annotation metadata
        #######################################################################

        plot_metadata <- meta_tree %>%
            dplyr::select(
                label,
                all_of(column)
            )

        if (grepl("^Cluster_", column)) {
            plot_metadata[[column]] <- sub(
                "^SNP[0-9]+_C00",
                "C",
                plot_metadata[[column]]
            )
        }


        #######################################################################
        # Prepare annotation variable
        #######################################################################

        if (type == "continuous") {

            numeric_values <- suppressWarnings(
                as.numeric(plot_metadata[[column]])
            )

            invalid_values <- (
                !is.na(plot_metadata[[column]]) &
                is.na(numeric_values)
            )

            if (any(invalid_values)) {

                stop(
                    paste0(
                        "Annotation column '",
                        column,
                        "' was declared continuous but ",
                        "contains non-numeric values."
                    ),
                    call. = FALSE
                )
            }

            plot_metadata[[column]] <- numeric_values

        } else {

            plot_metadata[[column]] <- as.factor(
                plot_metadata[[column]]
            )
        }


        #######################################################################
        # New fill scale
        #######################################################################

        p <- p +
            ggnewscale::new_scale_fill()


        #######################################################################
        # Annotation mapping
        #######################################################################

        annotation_mapping <- ggplot2::aes(
            y = label
        )

        annotation_mapping$fill <- rlang::sym(
            column
        )


        #######################################################################
        # Annotation track
        #######################################################################

        if (args$layout == "circular") {
            current_track_width <- 0.004

            if (i == 1) {
                # Gap between tree and first annotation ring
                current_track_spacing <- 0.032
            } else {
                # Gap between successive annotation ring
                current_track_spacing <- 0.036
            }
        
        } else {
            current_track_width <- track_width / (1 + 0.06 * (i - 1))

            if (i == 1) {
                # Gap between tree and first annotation track
                current_track_spacing <- 0.05
            } else {
                # Gap between successive annotation tracks
                current_track_spacing <- 0.06
            }
        }

        p <- p +
            ggtreeExtra::geom_fruit(
                data = plot_metadata,
                geom = geom_tile,
                mapping = annotation_mapping,
                width = current_track_width,
                offset = current_track_spacing,
            )


        #######################################################################
        # Annotation scale
        #######################################################################

        if (type == "continuous") {

            if (args$layout == "circular") {

                annotation_guide <- ggplot2::guide_colorbar(
                    order = annotation_order,
                    barwidth = grid::unit(6, "cm")
                )

            } else {

                annotation_guide <- ggplot2::guide_colorbar(
                    order = annotation_order
                )
            }

            p <- p +
                ggplot2::scale_fill_viridis_c(
                    name = annotation_label,
                    option = "D",
                    na.value = "grey90",
                    guide = annotation_guide
                )

        } else if (type == "binary") {

            annotation_colors <- get_binary_colors(
                plot_metadata[[column]]
            )

            p <- p +
                ggplot2::scale_fill_manual(
                    name = annotation_label,
                    values = annotation_colors,
                    na.value = "grey90",
                    guide = ggplot2::guide_legend(
                        order = annotation_order
                    )
                )

        } else {

            annotation_colors <- get_categorical_colors(
                plot_metadata[[column]]
            )

            p <- p +
                ggplot2::scale_fill_manual(
                    name = annotation_label,
                    values = annotation_colors,
                    na.value = "grey90",
                    guide = ggplot2::guide_legend(
                        order = annotation_order
                    )
                )
        }
    }
}

###############################################################################
# Annotation track labels
###############################################################################

if (
    length(annotations) > 0 &&
    args$layout == "rectangular"
) {

    # Build plot to obtain the actual x positions of annotation tracks
    built_plot <- ggplot2::ggplot_build(p)

    # geom_fruit tracks are geom_tile layers.
    tile_layers <- which(
        vapply(
            built_plot$data,
            function(x) {
                all(c("xmin", "xmax", "ymin", "ymax") %in% names(x))
            },
            logical(1)
        )
    )

    # Keep the last N tile layers, corresponding to annotation tracks
    tile_layers <- tail(
        tile_layers,
        length(track_labels)
    )

    track_x <- vapply(
        tile_layers,
        function(i) {
            mean(
                range(
                    c(
                        built_plot$data[[i]]$xmin,
                        built_plot$data[[i]]$xmax
                    ),
                    na.rm = TRUE
                )
            )
        },
        numeric(1)
    )

    # Position labels slightly above the tree
    label_y <- length(tree$tip.label) + 0.5

    label_data <- data.frame(
        x = track_x,
        y = label_y,
        label = track_labels
    )

    p <- p +
        ggplot2::geom_text(
            data = label_data,
            mapping = ggplot2::aes(
                x = x,
                y = y,
                label = label
            ),
            inherit.aes = FALSE,
            angle = 45,
            hjust = 0,
            vjust = 0,
            size = 2.2,
            fontface = "bold"
        ) +
        ggplot2::coord_cartesian(
            clip = "off"
        )
}

###############################################################################
# Theme
###############################################################################

p <- p +

    theme(
        legend.position = "right",

        legend.title = element_text(
            size = 11,
            face = "bold"
        ),

        legend.text = element_text(
            size = 9
        ),

        plot.margin = margin(
            t = 40,
            r = 10,
            b = 10,
            l = 10
        )
    )

###############################################################################
# Circular layout theme
###############################################################################

if (args$layout == "circular") {

    p <- p +
        ggplot2::theme(
            legend.position = "bottom",
            legend.box = "vertical",

            legend.title = ggplot2::element_text(
                size = 8,
                face = "bold"
            ),

            legend.text = ggplot2::element_text(
                size = 7
            ),

            legend.key.size = grid::unit(
                0.35,
                "cm"
            )
        )
}

###############################################################################
# Output directory
###############################################################################

output_dir <- dirname(
    args$output
)

if (
    output_dir != "."
    &&
    !dir.exists(output_dir)
) {

    dir.create(
        output_dir,
        recursive = TRUE
    )
}

###############################################################################
# Export
###############################################################################

png_file <- paste0(
    args$output,
    ".png"
)

svg_file <- paste0(
    args$output,
    ".svg"
)


###############################################################################
# Prepare final plot
###############################################################################

if (args$layout == "circular" && !is.null(scale_grob)) {

    # Convert the ggplot object to a graphical table.
    final_plot <- ggplot2::ggplotGrob(p)

    # Overlay the tree scale as an independent graphical object.
    #
    # The scale is deliberately added outside the circular coordinate system,
    # so it remains horizontal regardless of the tree layout.

    final_plot <- gtable::gtable_add_grob(
        final_plot,
        grobs = scale_grob,
        t = 1,
        l = 1,
        b = nrow(final_plot),
        r = ncol(final_plot),
        z = Inf,
        clip = "off",
        name = "tree_scale"
    )

} else {

    final_plot <- p
}


###############################################################################
# PNG
###############################################################################

ggplot2::ggsave(
    filename = png_file,
    plot = final_plot,
    width = args$width,
    height = args$height,
    dpi = args$dpi,
    limitsize = FALSE
)


###############################################################################
# SVG
###############################################################################

ggplot2::ggsave(
    filename = svg_file,
    plot = final_plot,
    width = args$width,
    height = args$height,
    limitsize = FALSE
)


###############################################################################
# Summary
###############################################################################

cat("============================================================\n")
cat("Phylogeny generated successfully\n")
cat("============================================================\n")
cat("\n")

cat("Tree:\n")
cat("    ", args$tree, "\n", sep = "")

cat("Metadata:\n")
cat("    ", args$metadata, "\n", sep = "")

if (!is.null(args$root)) {
    cat("Root taxon:\n")
    cat("    ", args$root, "\n", sep = "")
}

cat("Layout:\n")
cat("    ", args$layout, "\n", sep = "")

cat("\n")

cat("Output:\n")
cat("    ", png_file, "\n", sep = "")
cat("    ", svg_file, "\n", sep = "")

cat("\n")
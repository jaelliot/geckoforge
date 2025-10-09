# TeX Live Verification Guide

Geckoforge ships the TeX Live **scheme-medium** profile (~2 GB). This strikes a balance between capability and stability for openSUSE Leap 15.6 while covering research papers, presentations, and graphics-heavy workflows.

## Installed components

Scheme-medium includes:

- Core LaTeX and pdfLaTeX engines
- XeLaTeX and LuaLaTeX for Unicode-heavy documents
- AMS, geometry, fontspec, microtype, and most math packages
- Beamer, TikZ/PGF, listings, minted (requires `pygmentize`), and algorithmic packages
- BibTeX + Biber for bibliography management
- Basic font collections (Latin Modern, TeX Gyre)

If you need more (`scheme-full`, language-specific fonts, etc.), see [Upgrading](#upgrading-scheme).

## Verification checklist

Run these tests after the first `home-manager switch` to confirm the toolchain.

1. **Hello world**
   ```bash
   cat <<'TEX' > ~/tex-tests/hello.tex
   \documentclass{article}
   \begin{document}
   Hello, TeX Live scheme-medium!
   \end{document}
   TEX
   pdflatex hello.tex
   ```
   Expected: Generates `hello.pdf` without missing package warnings.

2. **Bibliography (biblatex + biber)**
   ```bash
   cat <<'TEX' > ~/tex-tests/bib.tex
   \documentclass{article}
   \usepackage[backend=biber]{biblatex}
   \addbibresource{refs.bib}
   \begin{document}
   Citation~\cite{knuth}
   \printbibliography
   \end{document}
   TEX
   cat <<'BIB' > ~/tex-tests/refs.bib
   @book{knuth,
     author    = {Donald E. Knuth},
     title     = {The {TeX}book},
     year      = {1986},
     publisher = {Addison-Wesley}
   }
   BIB
   pdflatex bib.tex
   biber bib
   pdflatex bib.tex
   ```
   Expected: Bibliography renders and Biber runs without errors.

3. **Beamer presentation**
   ```bash
   cat <<'TEX' > ~/tex-tests/slides.tex
   \documentclass{beamer}
   \usetheme{Madrid}
   \title{Geckoforge}
   \begin{document}
   \frame{\titlepage}
   \frame{\frametitle{Agenda} \begin{itemize}\item Containers \item Nix \item TeX\end{itemize}}
   \end{document}
   TEX
   pdflatex slides.tex
   ```
   Expected: Two-slide PDF output with theme assets.

4. **TikZ graphics**
   ```bash
   cat <<'TEX' > ~/tex-tests/diagram.tex
   \documentclass{standalone}
   \usepackage{tikz}
   \begin{document}
   \begin{tikzpicture}
     \draw[thick, ->] (0,0) -- (2,0) node[right]{X};
     \draw[thick, ->] (0,0) -- (0,2) node[above]{Y};
     \draw (0,0) circle (1cm);
   \end{tikzpicture}
   \end{document}
   TEX
   pdflatex diagram.tex
   ```
   Expected: Circular diagram builds successfully.

5. **Graphics + minted** (requires Python `pygments`)
   ```bash
   pip install --user pygments
   cat <<'TEX' > ~/tex-tests/minted.tex
   \documentclass{article}
   \usepackage{minted}
   \begin{document}
   \begin{minted}{elixir}
   IO.puts("Hello from Phoenix")
   \end{minted}
   \end{document}
   TEX
   pdflatex -shell-escape minted.tex
   ```
   Expected: Syntax highlighted PDF. If `minted` fails, ensure Python and `pygments` are available.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `latexmk` missing | Install via `tlmgr install latexmk` or add `texlive.latexmk` to `home.packages`. |
| Missing font/package | Run `tlmgr search pkg` and install, or add to flake overlay for reproducibility. |
| Unicode issues | Switch to XeLaTeX or LuaLaTeX (`xelatex file.tex`). |
| Slow first build | TeX Live initializes caches on first run; subsequent builds are faster. |

### Upgrading scheme

To switch to `scheme-full`:

1. Edit `home/modules/development.nix` and replace `texlive.combined.scheme-medium` with `texlive.combined.scheme-full`.
2. Run `home-manager switch`.

Alternatively, use `tlmgr install <package>` for ad-hoc additions.

## Editor integration

- **VS Code:** Install the *LaTeX Workshop* extension. Configure `latex-workshop.latex.tools` to use `pdflatex` or `latexmk`.
- **Neovim:** Use [vimtex](https://github.com/lervag/vimtex) with `neovim-remote` for forward search.
- **Emacs:** Enable AUCTeX with Synctex for precise navigation.

## Performance tips

- Build with `latexmk -pdf -interaction=nonstopmode` for large documents.
- Use `latexmk -xelatex` when fonts require XeLaTeX.
- For CI/CD, cache `~/.texlive2024` to avoid repeated package downloads.

By following this checklist you can confirm that TeX Live scheme-medium is production-ready on Geckoforge. Document additional findings in `docs/daily-summaries/` if you encounter edge cases.

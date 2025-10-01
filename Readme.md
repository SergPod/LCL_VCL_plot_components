The SGraph components, originally released for Delphi 5/6/7 (latest version 2.4), were converted to Lazarus components with essentially the same object model (10.2016). Then, the code has been changed slightly a few times, while remaining largely backwards compatible. In 06.2025, the Lazarus package files (ver. 1.8) were modified to support both Lazarus (LCL) and Delphi 12 (VCL), using the same Pascal units. (The Lazarus package is sgr_lz.lpk, the Delphi 12 package is sgr_vcl.dpk.) It is a relatively simple graphic component. It is more of a gauge than a presentation element. Here are some features:

  * The Lazarus package has been used on Windows (7-11) and Linux (Kubuntu, Mint).
  * Panning and Zoom by mouse.
  * DrawPlot method to replicate a plot image.
  * Buffered screen paint (useful for Delphi VCL), can be off.
  * Copy to clipboard as DIB (or as Metafile, Windows only).
  * Custom Draw Events.
  * Custom series can be implemented easily.
  * LineAndPoints and SpectrLines as y(x) series.

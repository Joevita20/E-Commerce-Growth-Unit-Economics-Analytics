<?xml version='1.0'?>
<!--
  Custom Tableau palettes for this project.

  INSTALL:
    Copy this file to  ~/Documents/My Tableau Repository/Preferences.tps
    (replace the existing file, or merge the <color-palette> blocks into it),
    then RESTART Tableau Public. The palettes appear in the colour dropdown.

  These are not decorative choices. The set was checked with a colour-vision
  validator: the sequential ramp is single-hue and monotone in lightness, the
  dumbbell pair holds a wide lightness gap, and the emphasis pair pushes
  everything except the focal mark to a recessive neutral.
-->
<workbook>
  <preferences>

    <!-- Single accent + recessive neutral.
         Use for the funnel: the bar length already encodes magnitude, so a
         per-step colour ramp would be redundant double-encoding. One accent
         on the step that is the story instead. -->
    <color-palette name="Growth Emphasis" type="regular">
      <color>#2a78d6</color>  <!-- Focus   - blue 450 -->
      <color>#b7b6b0</color>  <!-- Context - neutral gray -->
    </color-palette>

    <!-- Two shades of ONE hue for the before/after dumbbell.
         Two different hues would imply two unrelated series; these are two
         states of the same measure. -->
    <color-palette name="Growth Dumbbell" type="regular">
      <color>#86b6ef</color>  <!-- First touch - blue 250 -->
      <color>#1c5cab</color>  <!-- Last touch  - blue 550 -->
    </color-palette>

    <!-- Sequential, single hue, light to dark. For the cohort heatmap. -->
    <color-palette name="Growth Sequential Blue" type="ordered-sequential">
      <color>#cde2fb</color>
      <color>#b7d3f6</color>
      <color>#9ec5f4</color>
      <color>#86b6ef</color>
      <color>#6da7ec</color>
      <color>#5598e7</color>
      <color>#3987e5</color>
      <color>#2a78d6</color>
      <color>#256abf</color>
      <color>#1c5cab</color>
      <color>#184f95</color>
      <color>#104281</color>
      <color>#0d366b</color>
    </color-palette>

    <!-- Diverging, warm/cool poles with a NEUTRAL GRAY midpoint.
         For any "change versus baseline" view. Never a hue at the midpoint -
         the middle must read as "nothing happened". -->
    <color-palette name="Growth Diverging" type="ordered-diverging">
      <color>#0d366b</color>
      <color>#2a78d6</color>
      <color>#86b6ef</color>
      <color>#f0efec</color>
      <color>#f2a3a2</color>
      <color>#e34948</color>
      <color>#a52322</color>
    </color-palette>

  </preferences>
</workbook>

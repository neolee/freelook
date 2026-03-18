final case class ThemeChoice(id: String, title: String, isDark: Boolean)

object ThemeSelector {
  def selectDefault(choices: Seq[ThemeChoice], prefersDark: Boolean): Option[ThemeChoice] = {
    choices.find(_.isDark == prefersDark).orElse(choices.headOption)
  }
}

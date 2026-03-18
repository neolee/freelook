case class ThemeChoice(id: String, title: String, isDark: Boolean)

val choices = Seq(
  ThemeChoice("github-dark", "GitHub Dark", isDark = true),
  ThemeChoice("github-light", "GitHub Light", isDark = false),
)

println(choices.find(_.isDark).map(_.title).getOrElse("none"))

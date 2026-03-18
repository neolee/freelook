data class ThemeChoice(
    val id: String,
    val title: String,
    val isDark: Boolean,
)

fun selectDefaultTheme(choices: List<ThemeChoice>, prefersDark: Boolean): ThemeChoice? {
    return choices.firstOrNull { it.isDark == prefersDark } ?: choices.firstOrNull()
}

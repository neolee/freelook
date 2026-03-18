using System;
using System.Collections.Generic;
using System.Linq;

public sealed record ThemeChoice(string Id, string Title, bool IsDark);

public static class ThemeSelector
{
    public static ThemeChoice? SelectDefault(IEnumerable<ThemeChoice> choices, bool prefersDark)
    {
        return choices.FirstOrDefault(choice => choice.IsDark == prefersDark)
            ?? choices.FirstOrDefault();
    }
}

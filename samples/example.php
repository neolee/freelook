<?php

declare(strict_types=1);

function default_theme(array $choices, bool $prefersDark): ?array
{
    foreach ($choices as $choice) {
        if (($choice['isDark'] ?? false) === $prefersDark) {
            return $choice;
        }
    }

    return $choices[0] ?? null;
}

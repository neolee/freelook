record PreviewSummary(String fileName, String language, boolean truncated) {
    String statusLine() {
        return "%s [%s] %s".formatted(
            fileName,
            language,
            truncated ? "truncated" : "ready"
        );
    }
}

public final class Example {
    private Example() {
    }

    private static PreviewSummary buildSummary() {
        return new PreviewSummary("build.gradle", "java", false);
    }

    public static void main(String[] args) {
        System.out.println(buildSummary().statusLine());
    }
}

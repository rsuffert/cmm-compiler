import java.util.HashMap;
import java.util.Map;

public class SymbolTable {
    private final Map<String, SymbolTableEntry> symbols;

    public SymbolTable() {
        symbols = new HashMap<>();
    }

    public void add(String name, SymbolTableEntry entry) {
        if (contains(name)) {
            throw new IllegalArgumentException("Symbol '" + name + "' already exists in the symbol table.");
        }
        symbols.put(name, entry);
    }

    public SymbolTableEntry get(String name) {
        return symbols.get(name);
    }

    public boolean contains(String name) {
        return symbols.containsKey(name);
    }

    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("SymbolTable{\n");
        for (Map.Entry<String, SymbolTableEntry> entry : symbols.entrySet()) {
            sb.append("  ").append(entry.getKey()).append(": ").append(entry.getValue()).append("\n");
        }
        sb.append("}");
        return sb.toString();
    }
}
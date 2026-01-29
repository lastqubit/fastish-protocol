const SOLIDITY_DEFAULTS = {
    uint: 0n,
    int: 0n,
    bytes: "0x",
    fixedBytes: "0x00", // for bytes1-bytes32
    bool: false,
    address: "0x0000000000000000000000000000000000000000",
    string: "",
    array: [],
};

export function getDefaultValue(type) {
    if (type === "array") return SOLIDITY_DEFAULTS.array;
    if (type.startsWith("uint")) return SOLIDITY_DEFAULTS.uint;
    if (type.startsWith("int")) return SOLIDITY_DEFAULTS.int;
    if (type.startsWith("bytes") && type !== "bytes") {
        const size = parseInt(type.replace("bytes", ""));
        return "0x" + "00".repeat(size);
    }
    return SOLIDITY_DEFAULTS[type] ?? null;
}
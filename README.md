# LStream Library

## Description

The LStream library provides function blocks that can be used to deserialize JSON and XML data streams for the user program and to serialize them again from the user program. In computer science, a stream is a sequence of data elements that are made available over time. Examples of these data element sequences include data formats such as JSON or XML. These are increasingly being used for the exchange of data from or to a web server.

Due to the increasing use of networking within plants and the advancement of the Internet of Things (IoT), the exchange of data using JSON or XML format plays an increasingly important role in automation technology. The LStream library makes it possible to convert the JSON and XML data formats into a format that is more compatible with a SIMATIC S7 Controller for further processing. It can also be used to create an XML format from abstract data for further processing.

This version of the library is usable in TIA Portal as a global library and in SIMATIC AX 

## Install this package

Enter:

```iec-st
apax add @simatic-ax/LStream-JSON-XML
```

> to install this package you need to login into the GitHub registry. You'll find more information [here](https://github.com/simatic-ax/.github/blob/main/docs/personalaccesstoken.md)

## Namespace

```iec-st
Simatic.Ax.LStream
```

## Features

- **Deserialization**: Convert JSON and XML streams into a tree structure suitable for S7-controllers.
- **Serialization**: Generate JSON/XML from the internal program data format.

## Documentation

For more detailed information, please refer to the following documents:
- [How to Use the LStream Library](docs/LStream_library_extended_documentation.md)
- [Setting Up a GitHub Self-Hosted Runner on Windows VM](docs/Create_TIAX_CICD_Self-Hosted_Runner.md)
- [Creating a CI/CD Pipeline for TIAX Library testing and release using GitHub Actions](docs/Create_TIAX_CICD_Pipeline_for_Github_Actions.md)

## Usage

### **LStream JSON Deserializer**

The function block `LStream_JsonDeserializer` allows you to parse a byte-array JSON stream and reconstruct its contents into a tree structure suitable for further processing on **SIMATIC S7 controllers**.

---

#### **Basic Functionality**

- **Deserializes:** Converts raw JSON (as a byte array) into a structured array of key-value pairs.
- **Selective key parsing:** Use search mode (`search := TRUE`) to extract only specified keys.
- **Handles:** JSON objects, arrays, and multi-dimensional arrays.
- **Output:** Results are returned as an array of `LStream_typeElement`.

---

#### **Interface**

| Variable      | Type                                   | Direction | Description                                         |
|---------------|----------------------------------------|-----------|-----------------------------------------------------|
| `execute`     | `Bool`                                 | Input     | Rising edge triggers the deserialization            |
| `search`      | `Bool`                                 | Input     | If `TRUE`, only keys defined in `tree` are parsed   |
| `done`        | `Bool`                                 | Output    | `TRUE` when parsing is complete                     |
| `busy`        | `Bool`                                 | Output    | `TRUE` while parsing is ongoing                     |
| `error`       | `Bool`                                 | Output    | `TRUE` if an error occurred                         |
| `status`      | `Word`                                 | Output    | Status/error code                                   |
| `resultCount` | `Int`                                  | Output    | Number of elements successfully parsed              |
| `tree`        | `Array[*] of LStream_typeElement`      | In/Out    | Output tree containing parsed result                |
| `raw`         | `Array[*] of Byte`                     | In/Out    | Input raw JSON data as byte array                   |

---

### **Example**

Typical usage in structured text:

```iec-st
USING Simatic.Ax.LStream;

VAR
    deserializer   : LStream_JsonDeserializer;
    rawBuffer      : ARRAY[0..255] OF BYTE := [ /* your JSON as bytes */ ];
    treeBuffer     : ARRAY[0..49] OF LStream_typeElement; // Sufficient size for your data
    keysOnly       : BOOL := FALSE; // TRUE: only specific keys defined in treeBuffer are parsed
END_VAR

// Trigger parsing
deserializer(
    execute := TRUE,            // Start parsing on rising edge
    search := keysOnly,         // Search mode if needed
    tree := treeBuffer,
    raw := rawBuffer
);

// Monitor these outputs
// deserializer.done  - TRUE when done
// deserializer.error - TRUE if error occurred
// deserializer.status - Returns status code
// deserializer.resultCount - Number of parsed elements
```

- On the **rising edge** of `execute`, parsing begins.
- The returned `treeBuffer` contains parsed keys, values, types, and metadata.
- Set `search := TRUE` to parse only the keys you define in `treeBuffer`.

---

### **Notes & Best Practices**

- **Buffer sizing:**  
  Ensure both `tree` and `raw` arrays are sized for your input and expected output.
- **Watchdog:**  
  Large JSON documents may take multiple PLC cycles due to watchdog protection in the block.
- **Error Handling:**  
    - `done = TRUE`, `error = FALSE`: Success  
    - `done = FALSE`, `error = TRUE`: Error. Check `status` for diagnostic codes.
- **Result Count:**  
  Use `resultCount` to see how many values were parsed.

---


### **LStream JSON Serializer**

The function block `LStream_JsonSerializer` enables you to serialize a structured array of key-value elements (`tree`) into a valid JSON byte array (`jsonByteArray`). This allows easy export/sharing of PLC data in modern JSON format.

---

#### **Basic Functionality**

- **Serializes:** Converts PLC data from the array of `LStream_typeElement` into correctly formatted JSON.
- **Handles:** Objects, arrays (including multidimensional), numbers, booleans, and strings.
- **Returns:** The serialized result as an array of bytes (`jsonByteArray`).

---

#### **Interface**

| Variable           | Type                                  | Direction  | Description                                             |
|--------------------|---------------------------------------|------------|---------------------------------------------------------|
| `execute`          | `Bool`                                | Input      | Rising edge triggers serialization                      |
| `done`             | `Bool`                                | Output     | `TRUE` when serialization done                          |
| `busy`             | `Bool`                                | Output     | `TRUE` while serialization is in progress               |
| `error`            | `Bool`                                | Output     | `TRUE` if an error occurred                             |
| `status`           | `Word`                                | Output     | Status/error code                                       |
| `count`            | `UInt`                                | Output     | Number of bytes written to `jsonByteArray`              |
| `tree`             | `Array[*] of LStream_typeElement`     | In/Out     | Input structure to be serialized                        |
| `jsonByteArray`    | `Array[*] of Byte`                    | In/Out     | Output JSON as byte array                               |

---

### **Example**

Typical usage in structured text:

```iec-st
USING Simatic.Ax.LStream;

VAR
    serializer     : LStream_JsonSerializer;
    treeBuffer     : ARRAY[0..49] OF LStream_typeElement;  // Fill or build this structure as needed
    jsonBuffer     : ARRAY[0..255] OF BYTE;                // Sufficient size for your expected JSON result
    serializeDone  : BOOL;
    serializeError : BOOL;
END_VAR

// Fill treeBuffer with your key/value/type structure

// Trigger serialization
serializer(
    execute := TRUE,            // Start on rising edge
    tree := treeBuffer,
    jsonByteArray := jsonBuffer
);

serializeDone  := serializer.done;     // TRUE when serialization finished
serializeError := serializer.error;    // TRUE if error occurred
// serializer.status = Status/error code
// serializer.count  = Number of bytes written to jsonBuffer
```

- On the **rising edge** of `execute`, the serializer starts processing.
- `jsonBuffer` will contain the serialized JSON as a byte array.
- Monitor `done`, `error`, `status`, and `count` for progress and troubleshooting.

---

### **Notes & Best Practices**

- **Buffer sizing:**  
  Ensure `jsonByteArray` is larger than your expected JSON output. If too small, serialization will fail with an error.
- **Tree integrity:**  
  Make sure your `tree` array is correctly built (keys, values, types, depth, closingElement, etc.).
- **Error handling:**  
    - `done = TRUE`, `error = FALSE`: Success  
    - `done = FALSE`, `error = TRUE`: Error. Check `status` for diagnostic codes.
- **Count:**  
  Use `count` to see how many bytes were written into `jsonByteArray`.

---


## TIAX library workflow

This repository includes as well the necessary steps for deploying this library in a TIA Portal project. The process is streamlined with integrated Apax scripts that automate the conversion steps.

By leveraging the TIAX workflow, your library blocks are know-how protected when imported into TIA Portal—only the interface is visible, ensuring your intellectual property is safeguarded.

### Prerequisites

Before you begin, ensure you have:

- TIA Portal installed on your Windows machine (see [Compatibility](https://docs.industrial-operations-x.siemens.cloud/r/en-us/ax/ax2tia-docs/7.0.16/converting-simatic-ax-libraries-to-tia-portal-libraries/compatibility) section for required versions)
- AX SDK V3.0.12 or higher
- AX STC (System Toolchain): Version 4.4.116 or higher
- A library built for one of the supported targets: 1500, vplc, or swcpu. LLVM-only libraries cannot be converted.

### Configuration

Update the `TIA_INSTALL_PATH` variable in your `apax.yml` to match your local TIA Portal installation directory:

```yaml
variables:
  TIA_INSTALL_PATH: "C:\\Program Files\\Siemens\\Automation\\Portal V19"
```

### Workflow Steps

####  Step 1: Create and Build Your AX Library

Create your SIMATIC AX library with all your blocks, functions, and types in the `src/` folder.

Build the library:

```bash
apax build
```

#### Step 2: Convert to Handover Documents

Export your compiled library to handover documents that TIA Portal can process

```bash
apax export-tia-handover-documents
```

This script runs the ax2tia command and generates handover files in ./bin/handover-folder/. These JSON and implementation files are ready for TIA Portal import.


#### Step 3: Generate TIA Portal Global Library

Convert the handover documents into a TIA Portal global library:
```bash
apax import-handover-documents-to-tia
```

This executes the TIA Portal Library Importer and generates a global library file (.al19 for TIA V19) in the ./lstream-tiax/ directory.

#### Step 4: Import into Your TIA Portal Project

1. Open your TIA Portal project
2. Navigate to Libraries → Global Libraries
3. Click the "Open global library" symbol
4. Select the generated .al19 file from ./lstream-tiax/
5. The library blocks will appear in the Types folder

#### Step 5: Use Blocks in Your Project

1. Instantiate blocks by dragging them from the Types folder into your code
2. Call the blocks from your ST code in the OB editor
3. Assign memory tags to the block's input and output parameters
4. Download your project to a PLC or PLCSIM
5. Debug online using the watch table if needed

#### Step 6: Iterate and Update

When modifying the library in Simatic AX:

1. Increment the version number in the `apax.yml` 
2. Run the complete workflow with a single command: 

```bash
apax create-lib
```
This rebuilds, exports and imports the library in one step.
## Contribution

Thanks for your interest in contributing. Everybody is free to report bugs, unclear documentation, and other problems regarding this repository in the issues section, or even better, is free to propose any changes to this repository using Merge Requests.

### Markdownlint-cli

This workspace will be checked by the [markdownlint-cli](https://github.com/igorshubovych/markdownlint-cli) (there is also documented ho to install the tool) tool in the CI workflow automatically.  
To avoid, that the CI workflow fails because of the markdown linter, you can check all markdown files locally by running the markdownlint with:

```sh
markdownlint **/*.md --fix
```

## License and Legal information

Please read the [Legal information](LICENSE.md)

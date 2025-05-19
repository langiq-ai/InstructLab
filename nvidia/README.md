# Training Large Language Models with InstructLab

InstructLab is an open-source framework by IBM/Red Hat for community-driven tuning of LLMs.  It uses a *taxonomy* of knowledge and skill recipes to generate synthetic training data and fine-tune models with minimal human-written examples.  This tutorial provides a detailed, step-by-step guide to installing InstructLab, preparing data, running training, evaluating models, and deploying or troubleshooting. It assumes a strong technical background and includes advanced topics like distributed training and community contribution workflows.

## 1. Setting Up the Environment

First, provision a compatible system and install prerequisites. InstructLab runs on macOS (Apple Silicon M1/M2/M3) or Linux (e.g. Fedora/Ubuntu); Windows users can use WSL2. You need a C++ compiler (e.g. GCC/Clang) for building native libraries. Install **Python 3.10 or 3.11** (supported; Python 3.12 is not yet supported). Plan for **\~60 GB free disk space** to hold models and data.

You will also need GPU libraries if using hardware acceleration. For **NVIDIA GPUs**, install CUDA drivers and toolkit; for **AMD GPUs**, install ROCm. (A CUDA-capable GPU is strongly recommended for training large models.)  Red Hat provides official container images (e.g. `redhat/instructlab:latest`) on Docker Hub and Quay that include all dependencies. You may run InstructLab inside a container engine (Docker or Podman) if preferred, but the steps below assume a native setup.

**Summary of prerequisites:**

* 64-bit macOS (M-series) or Linux (tested on Fedora/Ubuntu)
* C++ compiler (gcc/clang) for llama.cpp builds
* Python 3.10 or 3.11 (3.12 unsupported)
* NVIDIA CUDA (for GPU) or AMD ROCm (for GPU) if using hardware acceleration
* \~60 GB free disk space

Once the OS and drivers are ready, create a Python virtual environment and install InstructLab via pip. For example, on Linux or macOS:

```bash
python3.11 -m venv --upgrade-deps venv
source venv/bin/activate
pip install instructlab
```

If you have an NVIDIA GPU and want GPU acceleration, install the CUDA extras and vLLM as follows:

```bash
pip install 'instructlab[cuda]' \
   -C cmake.args="-DLLAMA_CUDA=on" \
   -C cmake.args="-DLLAMA_NATIVE=off"
pip install vllm@git+https://github.com/opendatahub-io/vllm@2024.08.01
```

For AMD GPUs (ROCm), use:

```bash
pip install 'instructlab[rocm]' \
   --extra-index-url https://download.pytorch.org/whl/rocm6.0 \
   -C cmake.args="-DLLAMA_HIPBLAS=on" \
   -C cmake.args="-DAMDGPU_TARGETS=all" \
   -C cmake.args="-DCMAKE_C_COMPILER=/opt/rocm/llvm/bin/clang" \
   -C cmake.args="-DCMAKE_CXX_COMPILER=/opt/rocm/llvm/bin/clang++" \
   -C cmake.args="-DCMAKE_PREFIX_PATH=/opt/rocm" \
   -C cmake.args="-DLLAMA_NATIVE=off"
```

For NVIDIA GPUs specifically, ensure you have the appropriate CUDA toolkit installed:

```bash
# Check CUDA availability
nvidia-smi

# If CUDA is not installed, follow NVIDIA's installation guide:
# https://developer.nvidia.com/cuda-downloads
```

When installing with CUDA support, you can specify the CUDA compute capability for your specific GPU to optimize performance:

```bash
# For RTX 30xx/40xx series GPUs (compute capability 8.6)
pip install 'instructlab[cuda]' \
   -C cmake.args="-DLLAMA_CUDA=on" \
   -C cmake.args="-DLLAMA_CUBLAS=on" \
   -C cmake.args="-DCMAKE_CUDA_ARCHITECTURES=86" \
   -C cmake.args="-DLLAMA_NATIVE=off"

# For older GPUs, replace the architecture value accordingly:
# RTX 20xx: 75
# GTX 10xx: 61
# GTX 9xx: 52
```

(*Tip:* On macOS you may need to run `xcode-select --install` to get a compiler. If a `pip install` fails with an "unsupported instruction `vpdpbusd`" error, retry adding `-C cmake.args="-DLLAMA_NATIVE=off"` to disable optimized assembly.)

You can verify your CUDA configuration by checking if PyTorch recognizes your GPU:

```bash
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}, Device count: {torch.cuda.device_count()}')"
```

Verify the installation by running:

```bash
ilab
```

You should see the InstructLab CLI usage help. If not, re-check your Python environment and dependencies. Also consider enabling shell completion for `ilab` (bash, zsh, or fish) as described in the docs to help discover commands.

## 2. Installing and Configuring InstructLab

After installing the `ilab` CLI, initialize its configuration. Run:

```bash
ilab config init
```

This creates a default config file (usually in `~/.config/instructlab/config.yaml` on Linux). You can edit this file to set paths or customize behaviors, but the defaults typically work. The CLI is now ready to use.

To view your current configuration settings:

```bash
ilab config show
```

You can modify specific settings as needed:

```bash
# Example: Change the models directory
ilab config set models_dir /path/to/custom/models

# Enable verbose logging
ilab config set log_level DEBUG
```

Next, set up the **taxonomy** directory. InstructLab expects a filesystem tree of "knowledge" and "skills" YAML files describing tasks. By default, `ilab` will look under your local data directory (e.g. `~/.local/share/instructlab/taxonomy/` on Linux, or `~/Library/Application Support/instructlab/taxonomy/` on macOS).

The taxonomy structure follows this pattern:
```
taxonomy/
├── knowledge/
│   └── domain/
│       └── subdomain/
│           └── topic/
│               └── qna.yaml
└── skills/
    └── category/
        └── subcategory/
            └── skill_name/
                └── qna.yaml
```

You can download and inspect the existing InstructLab taxonomy as a reference:

```bash
# Clone the official taxonomy repository
git clone https://github.com/instructlab/taxonomy.git instructlab-taxonomy
ls -la instructlab-taxonomy/knowledge/
ls -la instructlab-taxonomy/skills/
```

### Creating Effective Knowledge Entries

To contribute new knowledge/skills, create the appropriate directory structure and add a `qna.yaml` file. For example, to add a new knowledge item *Phoenix* under astronomy:

```bash
# Adjust path to your ILAB data directory
mkdir -p ~/.local/share/instructlab/taxonomy/knowledge/astronomy/constellations/Phoenix
```

Here's a comprehensive `qna.yaml` example for astronomical knowledge:

```yaml
version: 3
task_description: "Information about the Phoenix constellation, including its history, stars, and observational details"
created_by: "your_username"
seed_examples:
  - context: >-
      Phoenix is a minor constellation in the southern sky. It was first depicted on a celestial globe by Dutch astronomer Petrus Plancius in 1597/1598 based on observations by Dutch explorers. It was introduced by Johann Bayer in 1603 in his star atlas Uranometria. The brightest star is Alpha Phoenicis, or Ankaa, with an apparent magnitude of 2.4. The constellation contains the galaxies NGC 625 and NGC 37, and the globular cluster NGC 6752.
    question: "What is the Phoenix constellation and what are its notable features?"
    answer: >-
      The Phoenix constellation is a minor constellation located in the southern sky. Named after the mythical Phoenix bird, it has several notable features:
      
      1. Historical significance: It was first depicted by Dutch astronomer Petrus Plancius in 1597/1598 and was formally introduced in Johann Bayer's 1603 star atlas Uranometria.
      
      2. Brightest star: Alpha Phoenicis (also known as Ankaa), which has an apparent magnitude of 2.4.
      
      3. Deep sky objects: The constellation contains several interesting celestial bodies including the galaxies NGC 625 and NGC 37, and the globular cluster NGC 6752.
      
      4. Location: It's primarily visible from the Southern Hemisphere and appears low on the horizon or not at all from many parts of the Northern Hemisphere.

  - context: >-
      The name "Phoenix" refers to the mythical bird that cyclically regenerates or is reborn from the ashes of its predecessor. The mythology originated in ancient Egypt and was later adopted by the Greeks. In the Uranometria star atlas, the constellation represents this legendary bird.
    question: "What is the mythological significance of the Phoenix constellation's name?"
    answer: >-
      The Phoenix constellation is named after the legendary Phoenix bird from mythology, which carries significant symbolism:
      
      The Phoenix is a mythical bird that cyclically regenerates or is reborn from the ashes of its predecessor. This powerful symbol of renewal and resurrection originated in ancient Egyptian mythology and was later adopted and expanded upon by Greek culture.
      
      In Johann Bayer's 1603 star atlas Uranometria, where the constellation was formally introduced to Western astronomy, the constellation depicts this legendary bird in the southern sky.
      
      The choice of this name reflects the ancient practice of associating celestial patterns with mythological figures and creatures. The Phoenix's symbolism of immortality and cyclical renewal made it a fitting name for this permanent fixture in the night sky that appears to "rise" and "set" with the Earth's rotation.

  - context: >-
      Observing Phoenix requires a clear view of the southern sky. The best time to observe it in the Northern Hemisphere is during late autumn, when it may be visible low on the southern horizon from southerly locations. In the Southern Hemisphere, it's visible from August to December. The constellation is located at Right Ascension 0h 12m to 2h 25m and Declination -57° to -39°.
    question: "When and how can I best observe the Phoenix constellation?"
    answer: >-
      To best observe the Phoenix constellation:
      
      Timing:
      - Southern Hemisphere: Phoenix is most visible from August to December, making this the prime observing season.
      - Northern Hemisphere: Late autumn provides the best opportunity, though the constellation will appear very low on the southern horizon and only from southerly locations.
      
      Location requirements:
      - You'll need a clear, unobstructed view of the southern sky.
      - The constellation is found at coordinates Right Ascension 0h 12m to 2h 25m and Declination -57° to -39°.
      
      Observing tips:
      - Use binoculars or a small telescope to spot the constellation's brightest star, Alpha Phoenicis (Ankaa).
      - Dark sky conditions away from city lights will greatly enhance visibility.
      - Look for Phoenix near other southern constellations like Grus and Tucana.
      - A star chart or astronomy app can help identify the constellation's position relative to other celestial landmarks.
```

For a skill-based example, let's create a data science skill entry:

```bash
mkdir -p ~/.local/share/instructlab/taxonomy/skills/data_science/visualization/interactive_plots
```

Here's a comprehensive `qna.yaml` file for this skill:

```yaml
version: 3
task_description: "Creating interactive data visualizations with Python libraries"
created_by: "your_username"
seed_examples:
  - context: >-
      Interactive plots allow users to explore data by hovering, zooming, panning, or clicking elements. 
      Python libraries like Plotly, Bokeh, and HoloViews offer various interactive visualization capabilities.
    question: "How can I create an interactive scatter plot with Plotly in Python that allows hovering to see data point details?"
    answer: >-
      # Creating Interactive Scatter Plots with Plotly in Python
      
      Here's how to create an interactive scatter plot in Plotly that shows details when hovering over points:
      
      ```python
      import plotly.express as px
      import pandas as pd
      
      # Create or load your dataset
      df = pd.DataFrame({
          'x': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          'y': [5, 6, 7, 8, 2, 4, 3, 2, 1, 9],
          'size': [10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
          'category': ['A', 'B', 'C', 'A', 'B', 'C', 'A', 'B', 'C', 'A'],
          'descr': ['Point 1', 'Point 2', 'Point 3', 'Point 4', 'Point 5', 
                    'Point 6', 'Point 7', 'Point 8', 'Point 9', 'Point 10']
      })
      
      # Create interactive scatter plot with hover information
      fig = px.scatter(
          df, 
          x='x', 
          y='y', 
          size='size',
          color='category',
          hover_name='descr',
          hover_data={'x': True, 'y': True, 'size': True, 'category': True},
          title='Interactive Scatter Plot with Hover Data'
      )
      
      # Customize hover template (optional)
      fig.update_traces(
          hovertemplate='<b>%{hovertext}</b><br>X: %{x}<br>Y: %{y}<br>Size: %{marker.size}<br>Category: %{marker.color}'
      )
      
      # Add interactive features
      fig.update_layout(
          hoverlabel=dict(
              bgcolor="white",
              font_size=16,
              font_family="Rockwell"
          )
      )
      
      # Show the interactive plot
      fig.show()
      
      # Save as HTML file (optional)
      fig.write_html("interactive_scatter.html")
      ```
      
      Key points about this implementation:
      
      1. We use `plotly.express` (px) as a high-level API for easy plot creation
      2. The `hover_name` parameter sets the main title in the hover tooltip
      3. The `hover_data` parameter controls which columns appear in the tooltip
      4. Custom hover templates can be defined with `hovertemplate` for precise control
      5. The interactive features include:
         - Hovering to see data details
         - Zooming with mouse wheel or selection
         - Panning by clicking and dragging
         - Double-clicking to reset the view
         - Selecting specific data points
         - Saving the current view
      
      To view the plot, run the code in a Jupyter notebook or use a browser when calling `fig.show()`. The HTML file can be shared with others who don't have Python installed.

  - context: >-
      Dashboard creation allows for multiple interactive visualizations to be combined into a single interface. 
      Dash by Plotly is a Python framework for building web-based analytical applications.
    question: "Can you provide a step-by-step guide to creating a simple interactive dashboard with Dash in Python?"
    answer: >-
      # Building an Interactive Dashboard with Dash in Python
      
      Here's a comprehensive step-by-step guide to creating a simple interactive dashboard with Dash:
      
      ## Step 1: Install the necessary packages
      ```python
      pip install dash pandas plotly
      ```
      
      ## Step 2: Import the libraries and initialize the app
      ```python
      import dash
      from dash import dcc, html
      from dash.dependencies import Input, Output
      import plotly.express as px
      import pandas as pd
      
      # Initialize the Dash app
      app = dash.Dash(__name__, title="Data Analysis Dashboard")
      
      # For deployment
      server = app.server
      ```
      
      ## Step 3: Prepare your data
      ```python
      # Sample data - replace with your own dataset
      df = pd.DataFrame({
          'Date': pd.date_range(start='2023-01-01', periods=100, freq='D'),
          'Sales': [100 + i + i**1.5 for i in range(100)],
          'Expenses': [50 + i + i**1.2 for i in range(100)],
          'Region': ['North' if i % 4 == 0 else 'South' if i % 4 == 1 
                    else 'East' if i % 4 == 2 else 'West' for i in range(100)]
      })
      
      # Prepare data for region dropdown
      regions = df['Region'].unique()
      ```
      
      ## Step 4: Design the layout
      ```python
      app.layout = html.Div([
          # Dashboard header
          html.H1("Business Analytics Dashboard", 
                  style={'textAlign': 'center', 'color': '#503D36', 'fontSize': 40}),
          
          # Description
          html.Div([
              html.P("Interactive dashboard showing sales and expense trends")
          ], style={'textAlign': 'center', 'padding': '20px'}),
          
          # First row with filters
          html.Div([
              html.Div([
                  html.Label('Select Region:'),
                  dcc.Dropdown(
                      id='region-dropdown',
                      options=[{'label': region, 'value': region} for region in regions],
                      value=regions[0],
                      clearable=False
                  )
              ], style={'width': '30%', 'display': 'inline-block'})
          ]),
          
          # Second row with charts
          html.Div([
              # Time series chart
              html.Div([
                  html.Label('Sales & Expenses Over Time'),
                  dcc.Graph(id='time-series')
              ], style={'width': '70%', 'display': 'inline-block', 'padding': '0 20px'}),
              
              # Pie chart
              html.Div([
                  html.Label('Sales by Region'),
                  dcc.Graph(id='pie-chart')
              ], style={'width': '30%', 'display': 'inline-block'})
          ])
      ], style={'padding': '50px'})
      ```
      
      ## Step 5: Add callbacks to make it interactive
      ```python
      @app.callback(
          Output('time-series', 'figure'),
          [Input('region-dropdown', 'value')]
      )
      def update_timeseries(selected_region):
          filtered_df = df[df['Region'] == selected_region]
          
          fig = px.line(
              filtered_df, 
              x='Date', 
              y=['Sales', 'Expenses'],
              title=f'{selected_region} Region: Sales & Expenses Trends'
          )
          
          return fig
      
      @app.callback(
          Output('pie-chart', 'figure'),
          [Input('region-dropdown', 'value')]
      )
      def update_pie_chart(selected_region):
          region_data = df.groupby('Region')['Sales'].sum().reset_index()
          
          fig = px.pie(
              region_data,
              values='Sales',
              names='Region',
              title='Total Sales by Region',
              hole=0.3,
          )
          
          # Highlight the selected region
          fig.update_traces(
              marker=dict(
                  line=dict(
                      color=['#000' if r == selected_region else '#fff' for r in region_data['Region']],
                      width=[3 if r == selected_region else 1 for r in region_data['Region']]
                  )
              )
          )
          
          return fig
      ```
      
      ## Step 6: Run the app
      ```python
      if __name__ == '__main__':
          app.run_server(debug=True, port=8050)
      ```
      
      ## Key Features of this Dashboard:
      
      1. **Interactive Elements**:
         - Dropdown to filter by region
         - Hoverable charts with tooltips
         - Zoomable and panable time series
      
      2. **Visual Components**:
         - Time series chart for temporal analysis
         - Pie chart for proportion analysis
      
      3. **Responsive Design**:
         - Components are sized by percentage for better responsiveness
      
      4. **Real-time Updates**:
         - Charts update automatically when selections change
      
      To enhance this dashboard further, you could add:
      - Date range selectors
      - Additional metrics and KPIs
      - Data tables with sortable columns
      - Download buttons for data export
      - More advanced visualizations like heatmaps or choropleth maps
      
      After running the app, you can view it in your web browser at http://127.0.0.1:8050/
```

After creating your YAML files, validate them with the taxonomy command:

```bash
ilab taxonomy diff
```

This will show output similar to:
```
Found 2 new or changed taxonomy items:
- knowledge/astronomy/constellations/Phoenix
- skills/data_science/visualization/interactive_plots
```

Remember that you can also download existing taxonomy examples from the InstructLab repository:

```bash
# Download a specific example
curl -o ~/.local/share/instructlab/taxonomy/knowledge/example/qna.yaml \
  https://raw.githubusercontent.com/instructlab/taxonomy/main/knowledge/example/qna.yaml

# Or clone the entire taxonomy for reference
git clone https://github.com/instructlab/taxonomy.git reference-taxonomy
```

## 3. Preparing Training Data

InstructLab uses a structured YAML format to describe seed examples. Each `qna.yaml` file includes metadata and at least one example triple (context, question/instruction, answer). For instance, a file might look like:

```
version: 3
task_description: >-
  <description of the task>
created_by: username
seed_examples:
  - context: >-
      (background text or conversation context)
    question: >-
      (the user’s question or instruction)
    answer: >-
      (the ideal answer or solution)
```

Ensure your seed examples focus on the new content or skill you want to teach. Keep them concise (for example, under \~2300 words combined) to avoid overloading the model. You can include multiple examples in one YAML.

For domain adaptation, collect domain-specific knowledge as YAML facts and instructions. For example, if tuning a model for medical Q\&A, include relevant context and answers in the taxonomy. Use the *knowledge* category for factual information and *skills* (or *compositional skills*) for procedural or instructional tasks. Organize categories into branches (e.g. `knowledge/medicine` or `skills/diagnosis`).

After placing your YAML files, run:

```bash
# View differences since last run
ilab taxonomy diff

# Validate the entire taxonomy structure
ilab taxonomy validate

# Get detailed information about a specific taxonomy item
ilab taxonomy info knowledge/astronomy/constellations/Phoenix
```

To prepare for data generation, you can also inspect the current dataset configuration:

```bash
# Show the expected dataset paths
ilab config show datasets_dir

# List any existing datasets
ls -la $(ilab config show datasets_dir)
```

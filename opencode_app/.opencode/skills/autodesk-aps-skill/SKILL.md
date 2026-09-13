---
name: autodesk-aps-skill
description: >-
  Autodesk Platform Services (APS/Forge) REST APIs — OAuth, Data Management,
  Model Derivative, Viewer, Design Automation, Webhooks; Revit, Fusion 360,
  AutoCAD add-in development.
license: Apache-2.0
compatibility: opencode
category: CAD & Hardware Design
---

# Autodesk Platform Services (APS) Integration

Provenance: extracted from autodesk-specialist-subagent. Domain knowledge for APS, Revit, Fusion 360, and AutoCAD API integration.

## Autodesk Platform Services (APS) Overview

APS (formerly Forge) is Autodesk's cloud platform providing APIs for:
- **Data Management API**: Access BIM 360, ACC, and A360 data
- **Model Derivative API**: Convert 70+ CAD formats to SVF for viewing
- **Viewer API**: Embed 3D/2D viewers in web applications
- **Design Automation API**: Run Revit, AutoCAD, Inventor in the cloud
- **Webhooks API**: Event-driven automation
- **Reality Capture API**: Process photos into 3D models

### APS Documentation
- Developer Portal: https://aps.autodesk.com/
- API Documentation: https://aps.autodesk.com/en/docs/data/v2/developers_guide/overview/
- Tutorials: https://aps.autodesk.com/tutorials
- GitHub Samples: https://github.com/Autodesk-Forge

## Authentication Methods

### 1. Two-Legged OAuth (Client Credentials)
For server-to-server authentication without user context.

```typescript
import fetch from 'node-fetch';

interface APSConfig {
  clientId: string;
  clientSecret: string;
}

async function get2LeggedToken(config: APSConfig): Promise<string> {
  const response = await fetch('https://developer.api.autodesk.com/authentication/v2/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      client_id: config.clientId,
      client_secret: config.clientSecret,
      grant_type: 'client_credentials',
      scope: 'data:read data:write data:create bucket:create bucket:read',
    }),
  });

  const data = await response.json();
  return data.access_token;
}
```

### 2. Three-Legged OAuth (Authorization Code)
For user authentication with account access.

```typescript
const APS_CLIENT_ID = process.env.APS_CLIENT_ID!;
const APS_CLIENT_SECRET = process.env.APS_CLIENT_SECRET!;
const REDIRECT_URI = 'http://localhost:3000/api/auth/callback';

function getAuthorizationUrl(state: string): string {
  const params = new URLSearchParams({
    response_type: 'code',
    client_id: APS_CLIENT_ID,
    redirect_uri: REDIRECT_URI,
    scope: 'data:read data:write user-profile:read',
    state,
  });
  return `https://developer.api.autodesk.com/authentication/v2/authorize?${params}`;
}

async function exchangeCodeForToken(code: string): Promise<TokenResponse> {
  const response = await fetch('https://developer.api.autodesk.com/authentication/v2/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'authorization_code',
      code,
      client_id: APS_CLIENT_ID,
      client_secret: APS_CLIENT_SECRET,
      redirect_uri: REDIRECT_URI,
    }),
  });
  return response.json();
}

interface TokenResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: string;
}
```

### 3. Token Refresh

```typescript
async function refreshToken(refreshToken: string): Promise<TokenResponse> {
  const response = await fetch('https://developer.api.autodesk.com/authentication/v2/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      client_id: APS_CLIENT_ID,
      client_secret: APS_CLIENT_SECRET,
    }),
  });
  return response.json();
}
```

### Environment Setup

```bash
# Required environment variables
export APS_CLIENT_ID="your-client-id"
export APS_CLIENT_SECRET="your-client-secret"
export APS_REDIRECT_URI="http://localhost:3000/api/auth/callback"
```

### Getting APS Credentials

1. Go to https://aps.autodesk.com/
2. Sign in with Autodesk account
3. Create a new app in My Apps
4. Select required scopes
5. Copy Client ID and Client Secret
6. Configure callback URL for 3-legged OAuth

## Data Management API

### List Hubs (BIM 360 / ACC Projects)

```typescript
async function listHubs(accessToken: string): Promise<Hub[]> {
  const response = await fetch('https://developer.api.autodesk.com/project/v1/hubs', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });
  const data = await response.json();
  return data.data;
}

interface Hub {
  id: string;
  type: string;
  attributes: {
    name: string;
  };
}
```

### List Projects in a Hub

```typescript
async function listProjects(accessToken: string, hubId: string): Promise<Project[]> {
  const response = await fetch(
    `https://developer.api.autodesk.com/project/v1/hubs/${hubId}/projects`,
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    }
  );
  const data = await response.json();
  return data.data;
}

interface Project {
  id: string;
  type: string;
  attributes: {
    name: string;
  };
}
```

### List Folder Contents

```typescript
async function listFolderContents(
  accessToken: string,
  projectId: string,
  folderId: string
): Promise<Item[]> {
  const response = await fetch(
    `https://developer.api.autodesk.com/data/v1/projects/${projectId}/folders/${folderId}/contents`,
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    }
  );
  const data = await response.json();
  return data.data;
}

interface Item {
  id: string;
  type: string;
  attributes: {
    name: string;
    displayName: string;
  };
}
```

### Upload File to BIM 360 / ACC

```typescript
import * as fs from 'fs';
import * as path from 'path';

async function uploadFile(
  accessToken: string,
  projectId: string,
  folderId: string,
  filePath: string
): Promise<any> {
  const fileName = path.basename(filePath);
  const fileContent = fs.readFileSync(filePath);
  
  const response = await fetch(
    `https://developer.api.autodesk.com/data/v1/projects/${projectId}/storage`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        jsonapi: { version: '1.0' },
        data: {
          type: 'objects',
          attributes: {
            name: fileName,
          },
          relationships: {
            target: {
              data: { type: 'folders', id: folderId },
            },
          },
        },
      }),
    }
  );
  
  const storage = await response.json();
  
  const uploadUrl = storage.data.attributes?.uploadUrl || 
    `https://developer.api.autodesk.com/oss/v2/buckets/${storage.data.relationships?.target?.data?.id}/objects/${fileName}`;
    
  await fetch(uploadUrl, {
    method: 'PUT',
    body: fileContent,
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });
  
  return storage;
}
```

## Model Derivative API

### Translate File to SVF (for Viewer)

```typescript
async function translateToSVF(
  accessToken: string,
  urn: string
): Promise<TranslationJob> {
  const response = await fetch(
    'https://developer.api.autodesk.com/modelderivative/v2/designdata/job',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        'x-ads-force': 'true',
      },
      body: JSON.stringify({
        input: {
          urn,
        },
        output: {
          formats: [
            {
              type: 'svf',
              views: ['2d', '3d'],
            },
          ],
        },
      }),
    }
  );
  return response.json();
}

interface TranslationJob {
  result: string;
  urn: string;
  acceptedJobsCount: number;
}
```

### Check Translation Status

```typescript
async function getTranslationStatus(
  accessToken: string,
  urn: string
): Promise<TranslationStatus> {
  const response = await fetch(
    `https://developer.api.autodesk.com/modelderivative/v2/designdata/${urn}/manifest`,
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    }
  );
  return response.json();
}

interface TranslationStatus {
  status: 'pending' | 'processing' | 'success' | 'failed' | 'timeout';
  progress: string;
  urn: string;
  region: string;
}
```

### Get Model Metadata

```typescript
async function getModelMetadata(
  accessToken: string,
  urn: string
): Promise<ModelMetadata> {
  const response = await fetch(
    `https://developer.api.autodesk.com/modelderivative/v2/designdata/${urn}/metadata`,
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    }
  );
  return response.json();
}

interface ModelMetadata {
  data: {
    metadata: {
      name: string;
      role: string;
    }[];
  };
}
```

## Viewer Integration

### Basic Viewer Setup (HTML/JavaScript)

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Autodesk Viewer</title>
  <link rel="stylesheet" href="https://developer.api.autodesk.com/modelderivative/v2/viewers/7.*/style.min.css">
  <script src="https://developer.api.autodesk.com/modelderivative/v2/viewers/7.*/viewer3D.min.js"></script>
  <style>
    #viewer { width: 100%; height: 600px; }
  </style>
</head>
<body>
  <div id="viewer"></div>
  <script>
    const viewer = new Autodesk.Viewing.GuiViewer3D(
      document.getElementById('viewer'),
      { extensions: ['Autodesk.DocumentBrowser'] }
    );
    
    Autodesk.Viewing.Initializer({ env: 'AutodeskProduction' }, async () => {
      viewer.start();
      const accessToken = await getAccessToken();
      Autodesk.Viewing.Document.load(
        `urn:${encodeURIComponent(URN)}`,
        (doc) => {
          const viewables = doc.getRoot().getDefaultGeometry();
          viewer.loadDocumentNode(doc, viewables);
        },
        (error) => console.error('Load error:', error)
      );
    });
    
    async function getAccessToken() {
      const response = await fetch('/api/auth/token');
      const data = await response.json();
      return data.access_token;
    }
  </script>
</body>
</html>
```

### Next.js Viewer Component

```typescript
'use client';

import { useEffect, useRef } from 'react';

declare global {
  interface Window {
    Autodesk: any;
  }
}

interface ViewerProps {
  urn: string;
  accessToken: string;
}

export function AutodeskViewer({ urn, accessToken }: ViewerProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const viewerRef = useRef<any>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    const script = document.createElement('script');
    script.src = 'https://developer.api.autodesk.com/modelderivative/v2/viewers/7.*/viewer3D.min.js';
    script.onload = () => {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = 'https://developer.api.autodesk.com/modelderivative/v2/viewers/7.*/style.min.css';
      document.head.appendChild(link);

      initViewer();
    };
    document.head.appendChild(script);

    function initViewer() {
      if (!containerRef.current || !window.Autodesk) return;

      viewerRef.current = new window.Autodesk.Viewing.GuiViewer3D(
        containerRef.current
      );

      window.Autodesk.Viewing.Initializer(
        { env: 'AutodeskProduction', accessToken },
        () => {
          viewerRef.current.start();
          window.Autodesk.Viewing.Document.load(
            `urn:${btoa(urn)}`,
            (doc: any) => {
              const viewables = doc.getRoot().getDefaultGeometry();
              viewerRef.current.loadDocumentNode(doc, viewables);
            }
          );
        }
      );
    }

    return () => {
      viewerRef.current?.finish();
    };
  }, [urn, accessToken]);

  return <div ref={containerRef} style={{ width: '100%', height: '600px' }} />;
}
```

## Design Automation API (Revit in Cloud)

### Create Revit Design Automation App

```typescript
async function createAppBundle(accessToken: string, appBundlePath: string): Promise<string> {
  const response = await fetch(
    'https://developer.api.autodesk.com/da/us-east/v3/appbundles',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        id: 'MyRevitApp',
        engine: 'Autodesk.Revit+2024',
        description: 'My Revit Design Automation App',
      }),
    }
  );
  
  const data = await response.json();
  const uploadUrl = data.uploadParameters.endpoint;
  const formData = data.uploadParameters.formData;
  
  const form = new FormData();
  Object.entries(formData).forEach(([key, value]) => {
    form.append(key, value as string);
  });
  form.append('file', fs.createReadStream(appBundlePath));
  
  await fetch(uploadUrl, { method: 'POST', body: form });
  
  return data.id;
}
```

### Run Revit Workitem

```typescript
async function runRevitWorkitem(
  accessToken: string,
  inputFileUrl: string,
  outputFileUrl: string
): Promise<WorkitemResult> {
  const response = await fetch(
    'https://developer.api.autodesk.com/da/us-east/v3/workitems',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        activityId: 'MyRevitApp+test',
        arguments: {
          inputFile: {
            url: inputFileUrl,
            verb: 'get',
          },
          outputFile: {
            url: outputFileUrl,
            verb: 'put',
          },
          onComplete: {
            verb: 'post',
            url: 'https://my-server.com/callback',
          },
        },
      }),
    }
  );
  return response.json();
}

interface WorkitemResult {
  id: string;
  status: 'pending' | 'running' | 'success' | 'failed';
}
```

## MCP Servers (Beta)

In this configurator the 4 servers are **not shipped in the base config** — enable them wholesale via `./deploy/setup.sh --enable-pack autodesk` (Docker: `--build-arg OPENCODE_PACKS=autodesk`; needs `AUTODESK_API_KEY`). For standalone setups, add the entries below manually.

| Server | Status | Tools Pattern | Description |
|--------|--------|---------------|-------------|
| Revit MCP Server | Coming Soon | `autodesk-revit*` | Revit automation and integration |
| Model Data Explorer | Coming Soon | `autodesk-model-data*` | Query model data from 70+ formats |
| Fusion Data | Coming Soon | `autodesk-fusion*` | Manage Fusion projects and data |
| Help | Coming Soon | `autodesk-help*` | AI-powered tutorials and guides |

**Beta Access**: https://feedback.autodesk.com/enter/

### config.json MCP Entries

```json
{
  "mcp": {
    "servers": {
      "autodesk-revit": {
        "type": "remote",
        "url": "https://mcp.autodesk.com/revit/v1",
        "headers": {
          "Authorization": "Bearer {env:AUTODESK_API_KEY}"
        },
        "disabled": true
      },
      "autodesk-model-data": {
        "type": "remote",
        "url": "https://mcp.autodesk.com/model-data/v1",
        "headers": {
          "Authorization": "Bearer {env:AUTODESK_API_KEY}"
        },
        "disabled": true
      },
      "autodesk-fusion": {
        "type": "remote",
        "url": "https://mcp.autodesk.com/fusion/v1",
        "headers": {
          "Authorization": "Bearer {env:AUTODESK_API_KEY}"
        },
        "disabled": true
      },
      "autodesk-help": {
        "type": "remote",
        "url": "https://mcp.autodesk.com/help/v1",
        "headers": {
          "Authorization": "Bearer {env:AUTODESK_API_KEY}"
        },
        "disabled": true
      }
    }
  }
}
```

## Revit API (Desktop Add-ins)

### Revit C# Plugin Template

```csharp
using Autodesk.Revit.Attributes;
using Autodesk.Revit.DB;
using Autodesk.Revit.UI;

namespace MyRevitPlugin
{
    [Transaction(TransactionMode.Manual)]
    public class MyCommand : IExternalCommand
    {
        public Result Execute(
            ExternalCommandData commandData,
            ref string message,
            ElementSet elements)
        {
            var uiApp = commandData.Application;
            var doc = uiApp.ActiveUIDocument.Document;

            using (var tx = new Transaction(doc, "My Operation"))
            {
                tx.Start();
                
                // Your Revit API code here
                var wallType = new FilteredElementCollector(doc)
                    .OfClass(typeof(WallType))
                    .FirstOrDefault();
                
                tx.Commit();
            }

            return Result.Succeeded;
        }
    }
}
```

### Revit Add-in Manifest (.addin)

```xml
<?xml version="1.0" encoding="utf-8"?>
<RevitAddIns>
  <AddIn Type="Command">
    <Name>My Revit Plugin</Name>
    <Assembly>MyRevitPlugin.dll</Assembly>
    <AddInId>12345678-1234-1234-1234-123456789012</AddInId>
    <FullClassName>MyRevitPlugin.MyCommand</FullClassName>
    <Text>My Plugin</Text>
    <Description>My Revit plugin description</Description>
    <VisibilityMode>AlwaysVisible</VisibilityMode>
    <LanguageType>Unknown</LanguageType>
    <VendorId>MyCompany</VendorId>
    <VendorDescription>My Company</VendorDescription>
  </AddIn>
</RevitAddIns>
```

## Fusion 360 API

### Python Fusion 360 Add-in

```python
import adsk.core, adsk.fusion, traceback

def run(context):
    ui = None
    try:
        app = adsk.core.Application.get()
        ui = app.userInterface
        
        design = app.activeProduct
        rootComp = design.rootComponent
        
        # Create a sketch
        sketches = rootComp.sketches
        xyPlane = rootComp.xYConstructionPlane
        sketch = sketches.add(xyPlane)
        
        # Draw a rectangle
        lines = sketch.sketchCurves.sketchLines
        point0 = adsk.core.Point3D.create(0, 0, 0)
        point1 = adsk.core.Point3D.create(5, 0, 0)
        point2 = adsk.core.Point3D.create(5, 5, 0)
        point3 = adsk.core.Point3D.create(0, 5, 0)
        
        lines.addByTwoPoints(point0, point1)
        lines.addByTwoPoints(point1, point2)
        lines.addByTwoPoints(point2, point3)
        lines.addByTwoPoints(point3, point0)
        
        # Extrude
        profile = sketch.profiles.item(0)
        extrudes = rootComp.features.extrudeFeatures
        
        extInput = extrudes.createInput(
            profile, 
            adsk.fusion.FeatureOperations.NewBodyFeatureOperation
        )
        distance = adsk.core.ValueInput.createByReal(2)
        extInput.setDistanceExtent(False, distance)
        extrudes.add(extInput)
        
    except:
        if ui:
            ui.messageBox('Failed:\n{}'.format(traceback.format_exc()))
```

### JavaScript Fusion 360 Add-in

```javascript
function run(context) {
    const app = adsk.core.Application.get();
    const design = app.activeProduct;
    const root = design.rootComponent;
    
    const sketches = root.sketches;
    const sketch = sketches.add(root.xYConstructionPlane);
    
    const lines = sketch.sketchCurves.sketchLines;
    const p0 = adsk.core.Point3D.create(0, 0, 0);
    const p1 = adsk.core.Point3D.create(5, 0, 0);
    const p2 = adsk.core.Point3D.create(5, 5, 0);
    const p3 = adsk.core.Point3D.create(0, 5, 0);
    
    lines.addByTwoPoints(p0, p1);
    lines.addByTwoPoints(p1, p2);
    lines.addByTwoPoints(p2, p3);
    lines.addByTwoPoints(p3, p0);
    
    const profile = sketch.profiles.item(0);
    const extrudes = root.features.extrudeFeatures;
    
    const input = extrudes.createInput(
        profile,
        adsk.fusion.FeatureOperations.NewBodyFeatureOperation
    );
    input.setDistanceExtent(
        false,
        adsk.core.ValueInput.createByReal(2)
    );
    extrudes.add(input);
}
```

## AutoCAD .NET API

### AutoCAD Plugin (C#)

```csharp
using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;

namespace MyAutoCADPlugin
{
    public class MyCommands
    {
        [CommandMethod("DrawLine")]
        public void DrawLine()
        {
            var doc = Application.DocumentManager.MdiActiveDocument;
            var db = doc.Database;
            var ed = doc.Editor;

            using (var tx = db.TransactionManager.StartTransaction())
            {
                var bt = tx.GetObject(db.BlockTableId, OpenMode.ForRead) as BlockTable;
                var btr = tx.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite) 
                    as BlockTableRecord;

                var line = new Line(new Point3d(0, 0, 0), new Point3d(10, 10, 0));
                line.SetDatabaseDefaults();
                btr.AppendEntity(line);
                tx.AddNewlyCreatedDBObject(line, true);

                tx.Commit();
            }
        }
    }
}
```

## Webhooks

### Create Webhook

```typescript
async function createWebhook(
  accessToken: string,
  event: string,
  callbackUrl: string,
  scope: { folderId: string } | { hubId: string }
): Promise<Webhook> {
  const response = await fetch(
    'https://developer.api.autodesk.com/webhooks/v1/systems/data/events/' + event + '/hooks',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        callbackUrl,
        scope,
        hookAttribute: {},
      }),
    }
  );
  return response.json();
}

interface Webhook {
  hookId: string;
  tenant: string;
  callbackUrl: string;
  createdBy: string;
  event: string;
}

// Usage
await createWebhook(
  token,
  'dm.version.added',
  'https://my-server.com/webhooks/autodesk',
  { folderId: 'urn:adsk.wipprod:fs.folder:co.XXXXX' }
);
```

## Common Scenarios

### Scenario 1: Get All Files in a BIM 360 Project

```typescript
async function getAllFiles(
  accessToken: string,
  hubId: string,
  projectId: string
): Promise<Item[]> {
  const allFiles: Item[] = [];
  
  const folders = await listFolderContents(
    accessToken,
    projectId,
    'urn:adsk.wipprod:fs.folder:co.root'
  );
  
  async function traverseFolder(folderId: string) {
    const contents = await listFolderContents(accessToken, projectId, folderId);
    
    for (const item of contents) {
      if (item.type === 'folders') {
        await traverseFolder(item.id);
      } else if (item.type === 'items') {
        allFiles.push(item);
      }
    }
  }
  
  for (const folder of folders.filter(f => f.type === 'folders')) {
    await traverseFolder(folder.id);
  }
  
  return allFiles;
}
```

### Scenario 2: Batch Translate Files for Viewer

```typescript
async function batchTranslateForViewer(
  accessToken: string,
  urns: string[]
): Promise<void> {
  const translations = await Promise.all(
    urns.map(urn => translateToSVF(accessToken, urn))
  );
  
  for (const job of translations) {
    let status = await getTranslationStatus(accessToken, job.urn);
    
    while (status.status === 'pending' || status.status === 'processing') {
      await new Promise(r => setTimeout(r, 5000));
      status = await getTranslationStatus(accessToken, job.urn);
    }
    
    if (status.status === 'failed') {
      console.error(`Translation failed for ${job.urn}`);
    }
  }
}
```

### Scenario 3: Create Presigned URL for Upload

```typescript
async function getSignedUrl(
  accessToken: string,
  bucketKey: string,
  objectKey: string
): Promise<string> {
  const response = await fetch(
    `https://developer.api.autodesk.com/oss/v2/buckets/${bucketKey}/objects/${objectKey}/signedurl`,
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    }
  );
  const data = await response.json();
  return data.signedUrl;
}
```

## Troubleshooting

### Authentication Errors
- Verify Client ID and Secret are correct
- Check scopes match required permissions
- Ensure redirect URI matches app configuration
- Token may have expired - refresh it

### Model Derivative Failures
- Check file format is supported (70+ formats)
- Verify URN is base64-encoded
- Check translation status for error details
- Ensure file is not corrupted

### Viewer Not Loading
- Verify translation completed successfully
- Check access token has `data:read` scope
- Ensure URN is properly encoded
- Check browser console for errors

### Rate Limits
- APS has rate limits per endpoint
- Implement exponential backoff
- Cache tokens and results
- Use webhooks instead of polling

## Documentation References

- APS Developer Portal: https://aps.autodesk.com/
- API Documentation: https://aps.autodesk.com/en/docs/data/v2/developers_guide/overview/
- Viewer Documentation: https://aps.autodesk.com/model-derivative
- Revit API: https://www.revitapidocs.com/
- Fusion 360 API: https://help.autodesk.com/view/fusion360/enu/?guid=GUID-A92A4B10-3781-4925-94C6-47DA85A4F65A
- AutoCAD .NET API: https://help.autodesk.com/view/ACD/ENU/?guid=GUID-5D816E31-6B73-4D26-8C26-82CC84AC8B99
- MCP Servers: https://www.autodesk.com/solutions/autodesk-ai/autodesk-mcp-servers
- Beta Access: https://feedback.autodesk.com/enter/
- GitHub Samples: https://github.com/Autodesk-Forge

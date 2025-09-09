#!/usr/bin/env python3
"""
ciqx - Terminal-based IDE for Garmin Connect IQ Development
Built with SOLID principles and modern Python TUI frameworks
"""

import asyncio
import json
import subprocess
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional, Protocol, Any
import uuid
import yaml

import typer
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn
from rich.table import Table
from rich.tree import Tree
from rich.live import Live
from rich.layout import Layout
from rich.text import Text
from rich import print as rprint
from pydantic import BaseModel, Field
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Version
__version__ = "1.0.0"

# Global console
console = Console()

class AppType(str, Enum):
    """Garmin app types following enum pattern"""
    WATCHFACE = "watchface"
    DATAFIELD = "datafield" 
    WIDGET = "widget"
    APP = "app"

class Profile(str, Enum):
    """Build profiles"""
    DEBUG = "debug"
    RELEASE = "release"

@dataclass
class Device:
    """Device information (Value Object)"""
    id: str
    name: str
    resolution: str
    display_type: str

# Device registry (following Registry pattern)
DEVICES = {
    "fenix7": Device("fenix7", "fēnix 7", "260×260", "MIP"),
    "fenix7s": Device("fenix7s", "fēnix 7S", "240×240", "MIP"),
    "venu2": Device("venu2", "Venu 2", "416×416", "AMOLED"),
    "vivoactive4": Device("vivoactive4", "Vívoactive 4", "260×260", "MIP"),
    "epix2": Device("epix2", "Epix (Gen 2)", "416×416", "AMOLED"),
}

# Configuration Models (Pydantic for validation)
class SDKConfig(BaseModel):
    """SDK configuration"""
    path: Optional[str] = None
    auto_detect: bool = True

class ProjectConfig(BaseModel):
    """Project structure configuration"""
    manifest: str = "manifest.xml"
    src: List[str] = Field(default_factory=lambda: ["source"])
    resources: List[str] = Field(default_factory=lambda: ["resources"]) 
    out_dir: str = "build"
    app_type: AppType = AppType.WATCHFACE

class DevicesConfig(BaseModel):
    """Device targets configuration"""
    default: str = "fenix7"
    targets: List[str] = Field(default_factory=lambda: ["fenix7", "venu2"])

class SigningConfig(BaseModel):
    """Code signing configuration"""
    developer_key: str = "developer_key.der"

class CiqxConfig(BaseModel):
    """Main configuration model"""
    sdk: SDKConfig = Field(default_factory=SDKConfig)
    project: ProjectConfig = Field(default_factory=ProjectConfig)
    devices: DevicesConfig = Field(default_factory=DevicesConfig)
    signing: SigningConfig = Field(default_factory=SigningConfig)

# Domain Interfaces (Dependency Inversion Principle)
class Compiler(Protocol):
    """Compiler interface for different implementations"""
    def compile(self, target: str, profile: Profile, manifest: Path, output: Path, 
                dev_key: Path) -> bool:
        ...

class Emulator(Protocol):
    """Emulator interface"""
    def run(self, app_path: Path, device: str) -> subprocess.Popen:
        ...

class Logger(Protocol):
    """Logger interface"""
    def info(self, message: str) -> None: ...
    def error(self, message: str) -> None: ...
    def debug(self, message: str) -> None: ...

# Concrete Implementations (Single Responsibility)
class RichLogger:
    """Rich-based logger implementation"""
    
    def __init__(self, console: Console):
        self.console = console
    
    def info(self, message: str) -> None:
        self.console.print(f"ℹ️  {message}", style="blue")
    
    def error(self, message: str) -> None:
        self.console.print(f"❌ {message}", style="red") 
    
    def debug(self, message: str) -> None:
        self.console.print(f"🐛 {message}", style="dim")
    
    def success(self, message: str) -> None:
        self.console.print(f"✅ {message}", style="green")

class GarminCompiler:
    """Garmin MonkeyC compiler implementation"""
    
    def __init__(self, logger: Logger, sdk_path: Optional[Path] = None):
        self.logger = logger
        self.sdk_path = sdk_path or self._find_sdk()
    
    def _find_sdk(self) -> Optional[Path]:
        """Find Garmin SDK installation"""
        candidates = [
            Path.home() / ".Garmin" / "ConnectIQ" / "SDK",
            Path.home() / "Library" / "Application Support" / "Garmin" / "ConnectIQ" / "Sdks",
            Path("/Applications/Garmin Connect IQ SDK"),
        ]
        
        for candidate in candidates:
            if candidate.exists():
                # Look for versioned SDK
                if (candidate / "bin").exists():
                    return candidate
                else:
                    # Find versioned subdirectory
                    for subdir in candidate.iterdir():
                        if subdir.is_dir() and "connectiq-sdk" in subdir.name:
                            if (subdir / "bin").exists():
                                return subdir
        return None
    
    def compile(self, target: str, profile: Profile, manifest: Path, 
                output: Path, dev_key: Path) -> bool:
        """Compile project for target device"""
        if not self.sdk_path:
            self.logger.error("Garmin SDK not found")
            return False
        
        monkeyc = self.sdk_path / "bin" / "monkeyc"
        if not monkeyc.exists():
            self.logger.error(f"monkeyc not found at {monkeyc}")
            return False
        
        # Build command (use jungle file if available, otherwise manifest)
        jungle_file = Path("monkey.jungle")
        if jungle_file.exists():
            cmd = [
                str(monkeyc),
                "-d", target,
                "-f", str(jungle_file),
                "-o", str(output),
                "-y", str(dev_key)
            ]
        else:
            cmd = [
                str(monkeyc),
                "-f", str(manifest),
                "-o", str(output),
                "-d", target,
                "-y", str(dev_key)
            ]
        
        # Profile-specific flags
        if profile == Profile.DEBUG:
            cmd.extend(["-g"])
        elif profile == Profile.RELEASE:
            cmd.extend(["-r"])
        
        self.logger.info(f"Building {target} ({profile.value})...")
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            self.logger.success(f"Built {target} successfully")
            return True
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Build failed: {e.stderr}")
            return False

class GarminEmulator:
    """Garmin simulator implementation"""
    
    def __init__(self, logger: Logger, sdk_path: Optional[Path] = None):
        self.logger = logger
        self.sdk_path = sdk_path or self._find_sdk()
    
    def _find_sdk(self) -> Optional[Path]:
        """Find SDK (same as compiler)"""
        # Reuse the same logic as GarminCompiler
        compiler = GarminCompiler(self.logger)
        return compiler.sdk_path
    
    def run(self, app_path: Path, device: str) -> subprocess.Popen:
        """Run app in simulator"""
        if not self.sdk_path:
            raise RuntimeError("Garmin SDK not found")
        
        monkeydo = self.sdk_path / "bin" / "monkeydo"
        if not monkeydo.exists():
            raise RuntimeError(f"monkeydo not found at {monkeydo}")
        
        self.logger.info(f"Running {app_path.name} on {device}")
        
        return subprocess.Popen([
            str(monkeydo),
            str(app_path),
            device
        ], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

# Service Container (Dependency Injection)
class ServiceContainer:
    """DI container following Registry pattern"""
    
    def __init__(self):
        self._services: Dict[str, Any] = {}
        self._setup_default_services()
    
    def _setup_default_services(self):
        """Setup default service implementations"""
        logger = RichLogger(console)
        self.register("logger", logger)
        self.register("compiler", GarminCompiler(logger))
        self.register("emulator", GarminEmulator(logger))
    
    def register(self, name: str, service: Any):
        """Register a service"""
        self._services[name] = service
    
    def get(self, name: str) -> Any:
        """Get a service"""
        if name not in self._services:
            raise KeyError(f"Service {name} not registered")
        return self._services[name]

# Configuration Service (Single Responsibility)
class ConfigService:
    """Configuration management"""
    
    def __init__(self, config_path: Path = Path("ciqx.yml")):
        self.config_path = config_path
        self._config: Optional[CiqxConfig] = None
    
    def load(self) -> CiqxConfig:
        """Load configuration from file"""
        if not self.config_path.exists():
            # Create default config
            config = CiqxConfig()
            self.save(config)
            return config
        
        with open(self.config_path) as f:
            data = yaml.safe_load(f)
        
        self._config = CiqxConfig.model_validate(data)
        return self._config
    
    def save(self, config: CiqxConfig):
        """Save configuration to file"""
        with open(self.config_path, 'w') as f:
            yaml.dump(config.model_dump(exclude_defaults=True), f)
        self._config = config
    
    def get(self) -> CiqxConfig:
        """Get current config (load if not already loaded)"""
        if self._config is None:
            return self.load()
        return self._config

# File Watcher (Observer Pattern)
class ProjectWatcher(FileSystemEventHandler):
    """File system watcher for project changes"""
    
    def __init__(self, callback, patterns: List[str]):
        self.callback = callback
        self.patterns = patterns
        self.last_modified = 0
        
    def on_modified(self, event):
        """Handle file modification"""
        if event.is_directory:
            return
            
        # Debounce rapid changes
        now = time.time()
        if now - self.last_modified < 0.5:
            return
        self.last_modified = now
        
        # Check if file matches patterns
        file_path = Path(event.src_path)
        for pattern in self.patterns:
            if file_path.match(pattern):
                self.callback()
                break

# Commands (Command Pattern)
class CiqxApp:
    """Main application class following Facade pattern"""
    
    def __init__(self):
        self.container = ServiceContainer()
        self.config_service = ConfigService()
        self.logger = self.container.get("logger")
    
    def doctor(self):
        """Environment diagnostics"""
        self.logger.info("Running environment diagnostics...")
        
        config = self.config_service.get()
        compiler = self.container.get("compiler")
        
        # Check SDK
        if compiler.sdk_path and compiler.sdk_path.exists():
            self.logger.success(f"Connect IQ SDK found at: {compiler.sdk_path}")
        else:
            self.logger.error("Connect IQ SDK not found")
            return False
        
        # Check tools
        monkeyc = compiler.sdk_path / "bin" / "monkeyc"
        if monkeyc.exists():
            self.logger.success("monkeyc compiler found")
        else:
            self.logger.error("monkeyc not found")
            return False
        
        # Check developer key
        dev_key = Path(config.signing.developer_key)
        if dev_key.exists():
            self.logger.success("Developer key found")
        else:
            self.logger.error(f"Developer key not found: {dev_key}")
            self.logger.info("Generate with: openssl genrsa -out developer_key.pem 4096")
        
        self.logger.success("Environment check complete!")
        return True
    
    def init(self, app_type: AppType):
        """Initialize new project"""
        self.logger.info(f"Initializing {app_type.value} project...")
        
        # Create project structure
        Path("source").mkdir(exist_ok=True)
        Path("resources").mkdir(exist_ok=True)
        Path("resources/drawables").mkdir(exist_ok=True)
        Path("resources/strings").mkdir(exist_ok=True)
        
        # Generate manifest
        app_id = str(uuid.uuid4())
        manifest_content = f'''<iq:manifest xmlns:iq="http://www.garmin.com/xml/connectiq" version="3">
    <iq:application entry="{app_type.value.title()}App" id="{app_id}" launcherIcon="@Drawables.LauncherIcon" name="@Strings.AppName" type="{app_type.value}" version="1.0.0">
        <iq:products>
            <iq:product id="fenix7"/>
            <iq:product id="venu2"/>
            <iq:product id="vivoactive4"/>
        </iq:products>
        <iq:permissions/>
        <iq:languages>
            <iq:language>eng</iq:language>
        </iq:languages>
    </iq:application>
</iq:manifest>'''
        
        with open("manifest.xml", "w") as f:
            f.write(manifest_content)
        
        # Create default config
        config = CiqxConfig()
        config.project.app_type = app_type
        self.config_service.save(config)
        
        self.logger.success(f"{app_type.value} project initialized!")
    
    def build(self, target: str, profile: Profile, build_all: bool = False):
        """Build project"""
        config = self.config_service.get()
        compiler = self.container.get("compiler")
        
        manifest = Path(config.project.manifest)
        out_dir = Path(config.project.out_dir)
        out_dir.mkdir(exist_ok=True)
        dev_key = Path(config.signing.developer_key)
        
        if build_all:
            success_count = 0
            with Progress(SpinnerColumn(), TextColumn("[progress.description]{task.description}"), 
                         BarColumn(), console=console) as progress:
                
                task = progress.add_task("Building...", total=len(config.devices.targets))
                
                for device in config.devices.targets:
                    progress.update(task, description=f"Building {device}")
                    output = out_dir / f"{device}-{profile.value}.prg"
                    
                    if compiler.compile(device, profile, manifest, output, dev_key):
                        success_count += 1
                    
                    progress.advance(task)
            
            if success_count == len(config.devices.targets):
                self.logger.success(f"Built all {success_count} targets successfully")
            else:
                self.logger.error(f"Built {success_count}/{len(config.devices.targets)} targets")
        else:
            output = out_dir / f"{target}-{profile.value}.prg"
            compiler.compile(target, profile, manifest, output, dev_key)
    
    def run(self, target: str, profile: Profile = Profile.DEBUG):
        """Build and run in simulator"""
        # Build first
        self.build(target, profile)
        
        # Run in emulator
        config = self.config_service.get()
        out_dir = Path(config.project.out_dir)
        app_path = out_dir / f"{target}-{profile.value}.prg"
        
        if not app_path.exists():
            self.logger.error(f"App not found: {app_path}")
            return
        
        emulator = self.container.get("emulator")
        process = emulator.run(app_path, target)
        
        # Stream output
        try:
            while True:
                output = process.stdout.readline()
                if output == '' and process.poll() is not None:
                    break
                if output:
                    console.print(f"[dim][SIM][/dim] {output.strip()}")
        except KeyboardInterrupt:
            self.logger.info("Stopping simulator...")
            process.terminate()
    
    def watch(self, target: str, profile: Profile = Profile.DEBUG):
        """Watch for changes and rebuild/rerun"""
        self.logger.info(f"Starting watch mode for {target} ({profile.value})")
        self.logger.info("Press Ctrl+C to stop")
        
        def rebuild():
            self.logger.info("Files changed, rebuilding...")
            self.build(target, profile)
            # Could also restart emulator here
        
        watcher = ProjectWatcher(rebuild, ["source/**/*.mc", "resources/**/*", "manifest.xml"])
        observer = Observer()
        observer.schedule(watcher, ".", recursive=True)
        observer.start()
        
        try:
            # Initial build and run
            self.run(target, profile)
            
            # Keep watching
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            observer.stop()
            self.logger.info("Watch mode stopped")
        observer.join()

# CLI Interface using Typer
app = typer.Typer(name="ciqx", help="Terminal IDE for Garmin Connect IQ Development")
ciqx = CiqxApp()

@app.command()
def doctor():
    """Check environment and SDK installation"""
    ciqx.doctor()

@app.command()  
def init(app_type: AppType = typer.Argument(AppType.WATCHFACE)):
    """Initialize new project"""
    ciqx.init(app_type)

@app.command()
def devices():
    """List available device targets"""
    table = Table(title="Garmin Connect IQ Devices")
    table.add_column("Device ID", style="cyan")
    table.add_column("Name", style="green")
    table.add_column("Resolution", style="yellow")
    table.add_column("Display", style="magenta")
    
    for device in DEVICES.values():
        table.add_row(device.id, device.name, device.resolution, device.display_type)
    
    console.print(table)

@app.command()
def build(
    target: str = typer.Option("fenix7", "-t", "--target", help="Target device"),
    profile: Profile = typer.Option(Profile.DEBUG, "-p", "--profile", help="Build profile"),
    all_targets: bool = typer.Option(False, "-a", "--all", help="Build for all targets")
):
    """Build project"""
    ciqx.build(target, profile, all_targets)

@app.command() 
def run(
    target: str = typer.Option("fenix7", "-t", "--target", help="Target device"),
    profile: Profile = typer.Option(Profile.DEBUG, "-p", "--profile", help="Build profile")
):
    """Build and run in simulator"""
    ciqx.run(target, profile)

@app.command()
def watch(
    target: str = typer.Option("fenix7", "-t", "--target", help="Target device"),
    profile: Profile = typer.Option(Profile.DEBUG, "-p", "--profile", help="Build profile")
):
    """Watch for changes and rebuild/rerun"""
    ciqx.watch(target, profile)

@app.command()
def version():
    """Show version"""
    console.print(f"ciqx {__version__}")

if __name__ == "__main__":
    app()
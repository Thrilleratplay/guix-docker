"""Convert Guix pack tarball to docker image."""
#!/usr/bin/python3

from argparse import ArgumentParser
from datetime import datetime
from tempfile import TemporaryDirectory
from typing import List, TypedDict, Dict
import hashlib
import json
import os
import shutil
import tarfile

###############################################################################
################################### Constants #################################
###############################################################################

DOCKER_IMAGE_NAME = "coreboot-base-env"
PARSE_DATE_FORMAT = "%Y-%m-%dT%H:%M:%S%z"
IMAGE_DATE_FORMAT = "%Y-%m-%dT%H:%M:%SZ"

###############################################################################
#################################### TYPES ####################################
###############################################################################

configDictType = TypedDict("configDictType", {"env": List[str]})
rootfsDictType = TypedDict("rootfsDictType", {"diff_ids": List[str], "type": str})
jsonDictType = TypedDict("jsonDictType", {"id": str, "created": str})


class ConfigJsonDict(TypedDict, total=False):
    """config.json dict type."""

    architecture: str
    comment: str
    config: configDictType
    created: str
    os: str
    rootfs: rootfsDictType


class ManifestJsonElementDict(TypedDict, total=False):
    """Single element dict type of manifest.json."""

    Config: str
    Layers: List[str]
    RepoTags: List[str]


###############################################################################
###################################  Methods ##################################
###############################################################################


class DockerImageMetadata:
    """Docker image metadata and json generation class."""

    config_dict: ConfigJsonDict
    manifest_dict: List[ManifestJsonElementDict]
    repositories_dict: Dict[str, Dict[str, str]]
    json_dict: jsonDictType
    config_sha256: str

    def __init__(self, tarball_path: str, commit_date: str) -> None:
        """Init."""
        tarball = tarfile.open(tarball_path)
        env_list = self.generate_env_list(tarball)
        tarball.close()

        tarball_sha256 = self.sha256_file_checksum(tarball_path)

        created_datetime = datetime.strptime(commit_date, PARSE_DATE_FORMAT)
        created_str = datetime.strftime(created_datetime, IMAGE_DATE_FORMAT)

        self.config_dict = {}
        self.config_dict["architecture"] = "386"
        self.config_dict["comment"] = "Generated by GNU Guix"
        self.config_dict["os"] = "linux"
        self.config_dict["config"] = {"env": env_list}
        self.config_dict["created"] = created_str
        self.config_dict["rootfs"] = {
            "diff_ids": ["sha256:" + tarball_sha256],
            "type": "layers",
        }

        self.config_sha256 = self.sha25_string_6checksum(self.config_json)

        manifest_item: ManifestJsonElementDict = {}
        manifest_item["Config"] = "config.json"
        manifest_item["Layers"] = [os.path.join(self.config_sha256, "layer.tar")]
        manifest_item["RepoTags"] = [DOCKER_IMAGE_NAME + ":latest"]
        self.manifest_dict = [manifest_item]

        self.repositories_dict = {}
        self.repositories_dict[DOCKER_IMAGE_NAME] = {"latest": self.config_sha256}

        self.json_dict = {"id": self.config_sha256, "created": created_str}

    def sha256_file_checksum(self, filename: str, block_size: int = 65536) -> str:
        """Sha256 of file."""
        # from https://gist.github.com/rji/b38c7238128edf53a181
        sha256 = hashlib.sha256()
        with open(filename, "rb") as f:
            for block in iter(lambda: f.read(block_size), b""):
                sha256.update(block)
        return sha256.hexdigest()

    def sha25_string_6checksum(self, string: str) -> str:
        """Sha256 of string."""
        # from https://stackoverflow.com/a/42200164
        return hashlib.sha256(string.encode("utf-8")).hexdigest()

    def format_env_path(
        self, var_name: str, guix_package: str, path_suffix: str = ""
    ) -> str:
        """Generate ENV Path."""
        return "{}=/gnu/store/{}/{}".format(var_name, guix_package, path_suffix)

    def generate_env_list(self, tarball: tarfile.TarFile) -> List[str]:
        """Set env list."""
        env: List[str] = []
        PATH_SET = False
        BASH_SET = False
        GIT_SET = False
        PYTHON_SET = False
        SSL_SET = False
        TERMINFO = False

        for file in tarball:
            split_path: List[str] = os.path.dirname(file.name).lstrip("./").split("/")

            if (
                len(split_path) > 2
                and split_path[0] == "gnu"
                and split_path[1] == "store"
            ):
                pkg_name = split_path[2]
                if pkg_name.endswith("-profile") and not PATH_SET:
                    env.append(self.format_env_path("PATH", pkg_name, "bin"))
                    env.append(self.format_env_path("CMAKE_PREFIX_PATH", pkg_name))
                    env.append(
                        self.format_env_path(
                            "PKG_CONFIG_PATH", pkg_name, "lib/pkgconfig"
                        )
                    )
                    PATH_SET = True
                elif "-bash-5" in pkg_name and not BASH_SET:
                    env.append(
                        self.format_env_path(
                            "BASH_LOADABLES_PATH", pkg_name, "lib/bash"
                        )
                    )
                    BASH_SET = True
                elif "-git-minimal-" in pkg_name and not GIT_SET:
                    env.append(
                        self.format_env_path(
                            "GIT_EXEC_PATH", pkg_name, "libexec/git-core"
                        )
                    )
                    GIT_SET = True
                elif "-python-minimal-3" in pkg_name and not PYTHON_SET:
                    env.append(
                        self.format_env_path(
                            "PYTHONPATH", pkg_name, "lib/python3.8/site-packages"
                        )
                    )
                    PYTHON_SET = True
                elif "-libressl-" in pkg_name and not SSL_SET:
                    env.append(
                        self.format_env_path("SSL_CERT_DIR", pkg_name, "etc/ssl/certs")
                    )
                    SSL_SET = True
                elif "-ncurses-" in pkg_name and not TERMINFO:
                    env.append(
                        self.format_env_path(
                            "TERMINFO_DIRS", pkg_name, "share/terminfo"
                        )
                    )
                    TERMINFO = True
        return env

    @property
    def config_json(self) -> str:
        """Return a JSON formated config object."""
        return json.dumps(self.config_dict)

    @property
    def manifest_json(self) -> str:
        """Return a JSON formated manifest object."""
        return json.dumps(self.manifest_dict)

    @property
    def repositories_json(self) -> str:
        """Return a JSON formated repositories object."""
        return json.dumps(self.repositories_dict)

    @property
    def json_json(self) -> str:
        """Return a JSON formated json object."""
        return json.dumps(self.json_dict)


###############################################################################
##################################  Execution #################################
###############################################################################

parser = ArgumentParser(description="Convert Guix pack tarball to docker image")
parser.add_argument("--tarball", help="Path to Guix pack tarball output")
parser.add_argument("--date", help="commit date, used as image creation date")
parser.add_argument("--commit", help="commit ID, used to create uniuqe file id")

args = parser.parse_args()
tarball_path: str = getattr(args, "tarball")
commit_date: str = getattr(args, "date")
commit_id: str = getattr(args, "commit")
commit_id_short: str = commit_id[:7]

output_file_name = "coreboot-build-docker-" + commit_id_short + ".tar"

image = DockerImageMetadata(tarball_path, commit_date)

with TemporaryDirectory() as tmpdir:
    os.chdir(tmpdir)
    os.mkdir(image.config_sha256)
    shutil.move(tarball_path, os.path.join(tmpdir, image.config_sha256, "layer.tar"))
    with open("config.json", "w") as config_json_file:
        config_json_file.write(image.config_json)
    with open("manifest.json", "w") as manifest_json_file:
        manifest_json_file.write(image.manifest_json)
    with open("repositories", "w") as repositories_file:
        repositories_file.write(image.repositories_json)
    with open(os.path.join(image.config_sha256, "json"), "w") as json_file:
        json_file.write(image.json_json)
    with open(os.path.join(image.config_sha256, "VERSION"), "w") as version_file:
        version_file.write("1.0")
    os.chdir("/")
    shutil.make_archive(output_file_name, "tar", root_dir=tmpdir, base_dir="./")
    # with tarfile.open("/" + output_file_name, mode="w") as archive:
    #     archive.add(tmpdir, filter=lambda x: os.path.relpath(x.name, tmpdir))
    shutil.move(
        "/" + output_file_name + ".tar", os.path.join("/output", output_file_name)
    )
    print("created ", output_file_name)
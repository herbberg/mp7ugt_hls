#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import toolbox as tb
import mp7patch

import argparse
import urllib
import shutil
import logging
from distutils.dir_util import copy_tree
import subprocess
import ConfigParser
import sys, os, re

EXIT_SUCCESS = 0
EXIT_FAILURE = 1

# Set correct FW_TYPE and BOARD_TYPE for each project!
FW_TYPE = 'ugt'
BOARD_TYPE = 'mp7'

BoardAliases = {
    'mp7_690es': 'r1',
    'mp7xe_690': 'xe',
}

DefaultBoardType = 'mp7xe_690'
DefaultVivadoVersion = '2018.2'
DefaultNrModules = '0'
DefaultMp7FwTag = 'mp7fw_v2_4_1'
vivado_base_dir_1 = '/opt/xilinx/Vivado'
vivado_base_dir_2 = '/opt/Xilinx/Vivado'

def run_command(*args):
    command = ' '.join(args)
    logging.info(">$ %s", command)
    os.system(command)

def vivado_t(version):
    """Validates Xilinx Vivado version number."""
    if not re.match(r'^\d{4}\.\d+$', version):
        raise ValueError("not a xilinx vivado version: '{version}'".format(**locals()))
    return version

Tcl_addHlsIpCore = 'addHlsIpCore.tcl'

def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument('builddir', help="build directory for HLS and FW synthesis")
    parser.add_argument('menupath', help="L1Menu directory path")
    parser.add_argument('menuname', help="L1Menu directory name")
    parser.add_argument('-v', '--vivado', type=vivado_t, default=DefaultVivadoVersion, help='xilinx vivado version to run (default: 2018.2)')
    parser.add_argument('-m', '--module', default=DefaultNrModules, help="MP7 module ID (default: 0)")
    parser.add_argument('-t', '--tag', metavar='<tag>', default=DefaultMp7FwTag, help="mp7fw tag (default: DefaultMp7FwTag)")
    parser.add_argument('-b', '--build', metavar='<version>', required=True, type=tb.build_t, help='menu build version (eg. 0x1001)')
    return parser.parse_args()

def main():
    """Main routine."""
    
    # Parse command line arguments.
    args = parse_args()
    
    settings64_1 = os.path.join(vivado_base_dir_1, args.vivado, 'settings64.sh')
    settings64_2 = os.path.join(vivado_base_dir_2, args.vivado, 'settings64.sh')
    if os.path.isfile(settings64_1):
        settings64 = settings64_1
    elif os.path.isfile(settings64_2):
        settings64 = settings64_2        
    else:
        raise RuntimeError(
            "no such Xilinx Vivado settings file '{settings64_1} or {settings64_2}'\n" \
            "  check if Xilinx Vivado {args.vivado} is installed on this machine.".format(**locals())
        )

    #source_vivado = 'bash -c "source {settings64}"'.format(**locals())
    #run_command(source_vivado)
    
    home = os.environ['HOME']

    menu_dir = '{home}/{args.menupath}/{args.menuname}'.format(**locals())
    work_dir = '{home}/{args.builddir}/{args.menuname}'.format(**locals())
        
    print '====================================================='
    print 'Menu directory: {menu_dir}'.format(**locals())
    print 'Build directory: {work_dir}'.format(**locals())
    print 'Vivado version: {args.vivado}'.format(**locals())
    print 'MP7 FW tag: {args.tag}'.format(**locals())
    print 'Build version: {args.build}'.format(**locals())
    print 'Module ID: {args.module}'.format(**locals())
    print '====================================================='
    print ''

    os.system('git clone https://github.com/herbberg/hls4gtl {work_dir}/hls4gtl'.format(**locals()))
    os.system('git clone https://github.com/herbberg/mp7ugt_hls {work_dir}/mp7ugt_hls'.format(**locals()))
    os.chdir('{work_dir}/hls4gtl'.format(**locals()))
    
    os.system('python manage.py init {menu_dir} {args.module}'.format(**locals()))

    session = "hls_0x{args.build}".format(**locals())
    logging.info("starting screen session '%s' for HLS and FW synthesis ...", session)
    
    command = ('bash -c "python manage.py cosim; python manage.py export; python {work_dir}/mp7ugt_hls/scripts/makeProject.py -t {args.tag} -b 0x{args.build} -m {menu_dir} --hls {work_dir}/hls4gtl/hls_impl/solution1/impl/ip -p {work_dir}/work; python {work_dir}/mp7ugt_hls/scripts/startSynth.py {args.vivado} {work_dir}/work/mp7_ugt/0x{args.build}/mp7fw_v2_4_1/build/build_0x{args.build}.cfg --screen no"'.format(**locals()))    
    run_command('screen', '-dmS', session, command)
    # list running screen sessions
    run_command('screen', '-ls')
    
if __name__ == '__main__':
    try:
        main()
    except RuntimeError, message:
        logging.error(message)
        sys.exit(EXIT_FAILURE)
    sys.exit(EXIT_SUCCESS)

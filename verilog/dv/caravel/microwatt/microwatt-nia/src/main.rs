use std::env;
use std::io::BufReader;
use std::fs::File;
use std::io;
use std::io::ErrorKind::InvalidInput;
use vcd::{ self, Value, ScopeItem };

fn read_vcd<R: io::Read>(r: &mut R) -> io::Result<()> {
    let mut parser = vcd::Parser::new(r);

    let header = parser.parse_header()?;

    // Find top level scope
    let top_scope = match &header.items[0] {
        ScopeItem::Scope(sc) => sc,
        x => panic!("Expected Scope, found {:?}", x),
    };

    let reset = header.find_var(&[&top_scope.identifier[..], "uut", "mprj", "microwatt_0", "ext_rst"])
                      .ok_or_else(|| io::Error::new(InvalidInput, "Could not find microwatt reset"))?.code;

    let nia = header.find_var(&[&top_scope.identifier[..], "uut", "mprj", "microwatt_0", "soc0", "processor", "debug_0", "nia"])
                    .ok_or_else(|| io::Error::new(InvalidInput, "Could not find microwatt nia signal"))?.code;

    let mut nia_val : u64;
    let mut in_reset = true;

    for command_result in parser {
        use vcd::Command::*;
        let command = command_result?;
        match command {
            ChangeVector(i, v) if i == nia => {
                if in_reset == false {
                    nia_val = 0;

                    for x in v.iter() {
                        match x {
                            Value::V1 => {
                                nia_val = (nia_val << 1) | 1;
                            }
                            Value::V0 => {
                                nia_val = (nia_val << 1) | 0;
                            }
                            _ => {
                                panic!("NIA is X or Z state");
                            }
                        }
                    }

                    println!("{:#018x}", nia_val);
                }
            }

            ChangeScalar(i, v) if i == reset => {
                if v == Value::V0{
                    in_reset = false;
                }
            }

            _ => (),
        }
    }

    Ok(())
}

fn main() -> std::io::Result<()> {
    let filename = env::args().nth(1).expect("No VCD file given");
    let file = File::open(filename)?;
    // The VCD parser isn't buffering reads, this speeds things up a bunch
    let mut reader = BufReader::new(file);

    read_vcd(&mut reader).expect("Failed to parse VCD file");

    Ok(())
}

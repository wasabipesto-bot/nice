//! The command-line reading shared by the middle-out examples
//! (`midout_bench`, `midout_wide_bench`, `midout_fields`): every option is
//! declared with its help, `--help` prints the usage, and an unknown option,
//! a missing value or a value that does not parse is refused with the
//! option's name.

use anyhow::{Context, Result, bail};
use std::collections::HashMap;
use std::str::FromStr;

/// One option: `--name VALUE` when `value` names the value, else a switch.
pub struct Opt {
    pub name: &'static str,
    pub value: Option<&'static str>,
    pub help: &'static str,
}

/// The options given.
pub struct Args {
    given: HashMap<&'static str, Option<String>>,
}

/// The usage text: `about`, then one line per option.
pub fn usage(prog: &str, about: &str, opts: &[Opt]) -> String {
    let mut s = format!("{about}\n\nusage: {prog} [OPTIONS]\n\noptions:\n");
    for o in opts {
        let left = o
            .value
            .map_or_else(|| o.name.to_string(), |v| format!("{} {v}", o.name));
        s.push_str(&format!("  {left:<22} {}\n", o.help));
    }
    s.push_str(&format!("  {:<22} print this and exit\n", "--help"));
    s
}

/// Read the process's arguments against `opts`. `--help` prints the usage
/// and exits.
///
/// # Errors
/// An unknown option, a missing value, or an option given twice.
pub fn parse(prog: &str, about: &str, opts: &'static [Opt]) -> Result<Args> {
    parse_from(prog, about, opts, std::env::args().skip(1))
}

fn parse_from(
    prog: &str,
    about: &str,
    opts: &'static [Opt],
    argv: impl IntoIterator<Item = String>,
) -> Result<Args> {
    let mut given = HashMap::new();
    let mut it = argv.into_iter();
    while let Some(a) = it.next() {
        if a == "--help" || a == "-h" {
            print!("{}", usage(prog, about, opts));
            std::process::exit(0);
        }
        let Some(o) = opts.iter().find(|o| o.name == a) else {
            bail!("unknown argument '{a}'\n\n{}", usage(prog, about, opts));
        };
        let v = match o.value {
            Some(placeholder) => match it.next() {
                Some(v) if !v.starts_with("--") => Some(v),
                _ => bail!("{} needs a value ({placeholder})", o.name),
            },
            None => None,
        };
        if given.insert(o.name, v).is_some() {
            bail!("{} given twice", o.name);
        }
    }
    Ok(Args { given })
}

impl Args {
    /// Whether a switch (or an option) was given.
    #[allow(dead_code)] // midout_fields has no switch
    pub fn flag(&self, name: &str) -> bool {
        self.given.contains_key(name)
    }

    /// An option's value, parsed, if given.
    ///
    /// # Errors
    /// A value that does not parse.
    pub fn opt<T: FromStr>(&self, name: &str) -> Result<Option<T>>
    where
        T::Err: std::error::Error + Send + Sync + 'static,
    {
        match self.given.get(name) {
            Some(Some(v)) => v
                .parse()
                .map(Some)
                .with_context(|| format!("{name} {v}: not a valid value")),
            _ => Ok(None),
        }
    }

    /// An option's value, parsed, or `default`.
    ///
    /// # Errors
    /// A value that does not parse.
    pub fn get<T: FromStr>(&self, name: &str, default: T) -> Result<T>
    where
        T::Err: std::error::Error + Send + Sync + 'static,
    {
        Ok(self.opt(name)?.unwrap_or(default))
    }

    /// A comma-separated list, parsed, if given.
    ///
    /// # Errors
    /// An element that does not parse, or an empty list.
    pub fn list<T: FromStr>(&self, name: &str) -> Result<Option<Vec<T>>>
    where
        T::Err: std::error::Error + Send + Sync + 'static,
    {
        let Some(Some(v)) = self.given.get(name) else {
            return Ok(None);
        };
        let out: Vec<T> = v
            .split(',')
            .map(|x| {
                x.parse()
                    .with_context(|| format!("{name} {v}: '{x}' is not a valid value"))
            })
            .collect::<Result<_>>()?;
        if out.is_empty() {
            bail!("{name}: an empty list");
        }
        Ok(Some(out))
    }
}

/// `--digits K0,K1,Q0`, if given: the three digit positions.
///
/// # Errors
/// Not three numbers.
#[allow(dead_code)] // not every example takes --digits
pub fn digits(a: &Args) -> Result<Option<(u32, u32, u32)>> {
    match a.list::<u32>("--digits")? {
        None => Ok(None),
        Some(d) if d.len() == 3 => Ok(Some((d[0], d[1], d[2]))),
        Some(d) => bail!("--digits K0,K1,Q0: three digit positions, not {d:?}"),
    }
}

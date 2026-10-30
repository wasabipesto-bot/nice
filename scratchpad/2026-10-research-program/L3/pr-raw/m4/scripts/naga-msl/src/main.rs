fn main() {
    let path = std::env::args().nth(1).unwrap();
    let src = std::fs::read_to_string(&path).unwrap();
    let module = naga::front::wgsl::parse_str(&src).unwrap_or_else(|e| panic!("{}", e.emit_to_string(&src)));
    let info = naga::valid::Validator::new(naga::valid::ValidationFlags::all(), naga::valid::Capabilities::all())
        .validate(&module)
        .unwrap_or_else(|e| panic!("{e:?}"));
    let mut options = naga::back::msl::Options::default();
    options.lang_version = (2, 4);
    let pipeline = naga::back::msl::PipelineOptions::default();
    let (msl, _) = naga::back::msl::write_string(&module, &info, &options, &pipeline).unwrap();
    print!("{msl}");
}

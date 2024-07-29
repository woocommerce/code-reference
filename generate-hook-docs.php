<?php

declare(strict_types=1);

namespace Automattic\WooCommerce\Tools;

/**
 * Generate documentation for hooks in WC
 */
class HookDocsGenerator
{

    /**
     * Source path.
     */
    protected const SOURCE_PATH = 'woocommerce/';

    /**
     * Hooks template path.
     */
    protected const HOOKS_TEMPLATE_PATH = 'build/api/hooks/hooks.html';

    /**
     * Search index path.
     */
    protected const SEARCH_INDEX_PATH = 'build/api/js/searchIndex.js';

    /**
     * List of files found.
     *
     * @var array
     */
    protected static $found_files = [];

    /**
     * Get files to scan.
     *
     * @return array
     */
    protected static function getFilesToScan(): array
    {
        $files = [];

        $files['Template Files']     = self::getFiles('*.php', GLOB_MARK, self::SOURCE_PATH . 'templates/');
        $files['Template Functions'] = array( self::SOURCE_PATH . 'includes/wc-template-functions.php', self::SOURCE_PATH . 'includes/wc-template-hooks.php' );
        $files['Shortcodes']         = self::getFiles('*.php', GLOB_MARK, self::SOURCE_PATH . 'includes/shortcodes/');
        $files['Widgets']            = self::getFiles('*.php', GLOB_MARK, self::SOURCE_PATH . 'includes/widgets/');
        $files['Data Stores']        = self::getFiles('*.php', GLOB_MARK, self::SOURCE_PATH . 'includes/data-stores');
        $files['Core Classes']       = array_merge(
            self::getFiles('*.php', GLOB_MARK, self::SOURCE_PATH . 'includes/'),
            self::getFiles('*.php', GLOB_MARK, self::SOURCE_PATH . 'includes/abstracts/'),
            self::getFiles('*.php', GLOB_MARK, self::SOURCE_PATH . 'includes/customizer/'),
            self::getFiles('*.php', GLOB_MARK, self::SOURCE_PATH . 'includes/emails/'),
            self::getFiles('*.php', GLOB_MARK, self::SOURCE_PATH . 'includes/export/'),
            self::getFiles('*.php', GLOB_MARK, self::SOURCE_PATH . 'includes/gateways/'),
            self::getFiles('*.php', GLOB_MARK, self::SOURCE_PATH . 'includes/import/'),
            self::getFiles('*.php', GLOB_MARK, self::SOURCE_PATH . 'includes/shipping/')
        );

        return array_filter($files);
    }

    /**
     * Get file URL.
     *
     * @param array $file File data.
     * @return string
     */
    protected static function getFileURL(array $file): string
    {
        $url = str_replace('.php', '.html#source-view.' . $file['line'], $file['path']);
        $url = str_replace(['_', '/'], '-', $url);

        return '../files/' . $url;
    }

    /**
     * Get file link.
     *
     * @param array $file File data.
     * @return string
     */
    protected static function getFileLink(array $file): string
    {
        return '<a href="../files/' . self::getFileURL($file) . '">' . basename($file['path']) . '</a>';
    }

    /**
     * Get files.
     *
     * @param string $pattern Search pattern.
     * @param int    $flags   Glob flags.
     * @param string $path    Directory path.
     * @return array
     */
    protected static function getFiles($pattern, $flags = 0, $path = '')
    {
        if (! $path && ( $dir = dirname($pattern) ) != '.') {
            if ('\\' == $dir || '/' == $dir) {
                $dir = '';
            }

            return self::getFiles(basename($pattern), $flags, $dir . '/');
        }

        $paths = glob($path . '*', GLOB_ONLYDIR | GLOB_NOSORT);
        $files = glob($path . $pattern, $flags);

        if (is_array($paths)) {
            foreach ($paths as $p) {
                $found_files = [];
                $retrieved_files = (array) self::getFiles($pattern, $flags, $p . '/');
                foreach ($retrieved_files as $file) {
                    if (! in_array($file, self::$found_files)) {
                        $found_files[] = $file;
                    }
                }

                self::$found_files = array_merge(self::$found_files, $found_files);

                if (is_array($files) && is_array($found_files)) {
                    $files = array_merge($files, $found_files);
                }
            }
        }
        return $files;
    }

    /**
     * Get hooks.
     *
     * @param array $files_to_scan Files to scan.
     * @return array
     */
    protected static function getHooks(array $files_to_scan): array
    {
        $scanned = [];
        $results = [];

        foreach ($files_to_scan as $heading => $files) {
            $hooks_found = [];

            foreach ($files as $f) {
                $current_file       = $f;
                $tokens             = token_get_all(file_get_contents($f));
                $token_type         = false;
                $current_class      = '';
                $current_function   = '';

                if (in_array($current_file, $scanned)) {
                    continue;
                }

                $scanned[] = $current_file;

                foreach ($tokens as $index => $token) {
                    if (is_array($token)) {
                        $trimmed_token_1 = trim($token[1]);
                        if (T_CLASS == $token[0]) {
                            $token_type = 'class';
                        } elseif (T_FUNCTION == $token[0]) {
                            $token_type = 'function';
                        } elseif ('do_action' === $token[1]) {
                            $token_type = 'action';
                        } elseif ('apply_filters' === $token[1]) {
                            $token_type = 'filter';
                        } elseif ($token_type && ! empty($trimmed_token_1)) {
                            switch ($token_type) {
                                case 'class':
                                    $current_class = $token[1];
                                    break;
                                case 'function':
                                    $current_function = $token[1];
                                    break;
                                case 'filter':
                                case 'action':
                                    $hook = trim($token[1], "'");
                                    $hook = str_replace('_FUNCTION_', strtoupper($current_function), $hook);
                                    $hook = str_replace('_CLASS_', strtoupper($current_class), $hook);
                                    $hook = str_replace('$this', strtoupper($current_class), $hook);
                                    $hook = str_replace(array( '.', '{', '}', '"', "'", ' ', ')', '(' ), '', $hook);
                                    $hook = preg_replace('/\/\/phpcs\:(.*)/', '', $hook);
                                    $loop = 0;

                                    // Keep adding to hook until we find a comma or colon.
                                    while (1) {
                                        $loop++;
                                        $prev_hook = is_string($tokens[ $index + $loop - 1 ]) ? $tokens[ $index + $loop - 1 ] : $tokens[ $index + $loop - 1 ][1];
                                        $next_hook = is_string($tokens[ $index + $loop ]) ? $tokens[ $index + $loop ] : $tokens[ $index + $loop ][1];

                                        if (in_array($next_hook, array( '.', '{', '}', '"', "'", ' ', ')', '(' ))) {
                                            continue;
                                        }

                                        if (in_array($next_hook, array( ',', ';' ))) {
                                            break;
                                        }

                                        $hook_first = substr($next_hook, 0, 1);
                                        $hook_last  = substr($next_hook, -1, 1);

                                        if ('{' === $hook_first || '}' === $hook_last || '$' === $hook_first || ')' === $hook_last || '>' === substr($prev_hook, -1, 1)) {
                                            $next_hook = strtoupper($next_hook);
                                        }

                                        $next_hook = str_replace(array( '.', '{', '}', '"', "'", ' ', ')', '(' ), '', $next_hook);

                                        $hook .= $next_hook;
                                    }

                                    $hook = trim($hook);

                                    if (isset($hooks_found[ $hook ])) {
                                        $hooks_found[ $hook ]['files'][] = ['path' => $current_file, 'line' => $token[2]];
                                    } else {
                                        $hooks_found[ $hook ] = [
                                            'files'    => [['path' => $current_file, 'line' => $token[2]]],
                                            'class'    => $current_class,
                                            'function' => $current_function,
                                            'type'     => $token_type,
                                        ];
                                    }
                                    break;
                            }
                            $token_type = false;
                        }
                    }
                }
            }

            foreach ($hooks_found as $hook => $details) {
                if (!strstr($hook, 'woocommerce') && !strstr($hook, 'product') && !strstr($hook, 'wc_')) {
                    // unset( $hooks_found[ $hook ] );
                }
            }

            ksort($hooks_found);

            if (!empty($hooks_found)) {
                $results[ $heading ] = $hooks_found;
            }
        }

        return $results;
    }

    /**
     * Get delimited list output.
     *
     * @param array $hook_list List of hooks.
     * @param array $files_to_scan List of files to scan.
     * @param string
     */
    protected static function getDelimitedListOutput(array $hook_list, array $files_to_scan): string
    {
        $output = '';

        $index = [];
        foreach ($files_to_scan as $heading => $files) {
            $index[] = '<a href="#hooks-' . str_replace(' ', '-', strtolower($heading)) . '">' . $heading . '</a>';
        }

        $output .= '<p>' . implode(', ', $index) . '</p>';

        $output .= '<div class="hooks-reference">';
        foreach ($hook_list as $heading => $hooks) {
            $output .= '<h2 id="hooks-' . str_replace(' ', '-', strtolower($heading)) . '">' . $heading . '</h2>';
            $output .= '<dl class="phpdocumentor-table-of-contents">';
            foreach ($hooks as $hook => $details) {
                $output .= '<dt class="phpdocumentor-table-of-contents__entry -' . $details['type'] . '">' . $hook . '</dt>';
                $link_list = [];
                foreach ($details['files'] as $file) {
                    $link_list[] = self::getFileLink($file);
                }
                $output .= '<dd>' . implode(', ', $link_list) . '</dd>';
            }
            $output .= '</dl>';
        }

        $output .= '</div>';

        return $output;
    }

    /**
     * Get JS output.
     *
     * @param array $hook_list List of hooks.
     * @param string
     */
    protected static function getJSOutput(array $hook_list): string
    {
        $output = '';

        foreach ($hook_list as $heading => $hooks) {
            foreach ($hooks as $hook => $details) {
                $type    = 'filter' === $details['type'] ? 'Filter' : 'Action';
                $summary = $heading . ' ' . $type;
                $name    = '<strong>' . $type . ' hook: <\/strong>' . $hook;

                foreach ($details['files'] as $file) {
                    $summary .= ' located in ' . str_replace('woocommerce/', '', $file['path']) . ': ' . $file['line'];

                    $output .= ',{';
                    $output .= 'fqsen: "' . $name . '",';
                    $output .= 'name: "' . $hook . '",';
                    $output .= 'summary: "' . $summary . '",';
                    $output .= 'url: "' . str_replace('../', 'https://woocommerce.github.io/code-reference/', self::getFileURL($file)) . '"';
                    $output .= '}';
                }
            }
        }

        return $output;
    }

    /**
     * Apply changes to build/.
     */
    public static function applyChanges()
    {
        $files_to_scan = self::getFilesToScan();
        $hook_list     = self::getHooks($files_to_scan);

        if (empty($hook_list)) {
            return;
        }

        // Add hooks reference content.
        if (file_exists(self::HOOKS_TEMPLATE_PATH)) {
            $output   = self::getDelimitedListOutput($hook_list, $files_to_scan);
            $template = file_get_contents(self::HOOKS_TEMPLATE_PATH);
            $template = str_replace('<!-- hooks -->', $output, $template);
            file_put_contents(self::HOOKS_TEMPLATE_PATH, $template);
        }

        // Add hooks to search index.
        if (file_exists(self::SEARCH_INDEX_PATH)) {
            $output   = self::getJSOutput($hook_list);
            $template = file_get_contents(self::SEARCH_INDEX_PATH);
            $template = str_replace('}];', '}' . $output . '];', $template);
            file_put_contents(self::SEARCH_INDEX_PATH, $template);
        }

        echo "Hook docs generated :)\n";
    }
}

HookDocsGenerator::applyChanges();
